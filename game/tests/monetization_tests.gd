extends RefCounted
## Store behavior is driven with SDK records and real RSA signatures, without charges.
class StoreStub extends Node:
	var connected: bool = true
	var purchases: int = 0
	var queries: int = 0
	var option: String = ""
	var result: int = 0
	func is_ready() -> bool:
		return connected
	func query_purchases(_type: int) -> void:
		queries += 1
	func query_product_details(_products: PackedStringArray, _type: int) -> void:
		pass
	func purchase(_id: String, choice: String) -> Dictionary:
		purchases += 1
		option = choice
		return {"response_code": result}
	func end_connection() -> void:
		pass

class UmpStub extends RefCounted:
	signal consent_updated(allowed: bool, required: bool, error: String)
	var requests: int = 0
	var shows: int = 0
	func request_update(_under_age: bool) -> void:
		requests += 1
	func show_privacy_options() -> void:
		shows += 1

func run(suite: SceneTree) -> void:
	var fixture_path: String = ProjectSettings.globalize_path("res://").path_join("../build/receipt-fixture.json")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var receipt: Dictionary = fixture.receipt
	var data: Dictionary = JSON.parse_string(Marshalls.base64_to_raw(receipt.payload).get_string_from_utf8())
	var verifier: VerifiedEntitlement = VerifiedEntitlement.new()
	verifier.public_key = fixture.public_key
	verifier.device_id = "a".repeat(64)
	var now: int = int(Time.get_unix_time_from_system())
	suite.check(verifier.claims(receipt, now, "b".repeat(64)).get("status") == "active", "Node-signed RSA receipt validates in Godot")
	suite.check(verifier.claims(receipt, int(data.expires_at)).is_empty(), "offline receipt expires exactly at deadline")
	suite.check(verifier.claims(receipt, int(data.issued_at) - 301).is_empty(), "future-dated receipt is rejected")
	suite.check(verifier.claims(receipt, now, "c".repeat(64)).is_empty(), "receipt from a previous verification request cannot be replayed")
	verifier.device_id = "d".repeat(64)
	suite.check(verifier.claims(receipt, now).is_empty(), "receipt copied to a different installation cannot grant Plus")
	verifier.device_id = "a".repeat(64)
	var altered: Dictionary = receipt.duplicate(true)
	data.expires_at = now + 999999
	altered.payload = Marshalls.raw_to_base64(JSON.stringify(data).to_utf8_buffer())
	suite.check(verifier.claims(altered, now).is_empty(), "edited receipt cannot grant or extend ownership")

	var service: NativeBilling = NativeBilling.new()
	service.cache_path = "user://test_play_entitlement.json"
	service.identity_path = "user://test_play_installation.txt"
	service.verifier = verifier
	service.config.production = true
	service.config.verification_url = "https://verifier.invalid/v1/play/verify"
	service.config.receipt_public_key = fixture.public_key
	service.config.purchase_option = "buy"
	var sdk: StoreStub = StoreStub.new()
	service.client = sdk
	service.add_child(sdk)
	suite.root.add_child(service)
	service.purchase()
	suite.check(sdk.purchases == 0, "purchase blocked until localized product details arrive")
	service._on_products({"response_code": 0, "product_details": [{"product_id": "remove_ads", "one_time_purchase_offer_details_list": [
		{"purchase_option_id": "rent", "formatted_price": "$0.99", "rental_details": {}},
		{"purchase_option_id": "buy", "formatted_price": "€2,19", "offer_id": null, "rental_details": null}]}]})
	suite.check(service.product_price == "€2,19" and service.can_purchase(), "exact permanent option uses Play's localized price and nullable SDK fields")
	service.purchase()
	service.purchase()
	suite.check(sdk.purchases == 1 and sdk.option == "buy", "rapid purchase taps launch one exact permanent purchase option")
	service._on_purchases({"response_code": 1})
	suite.check(not service.has_plus() and service.state == "cancelled", "cancelled purchase never grants")
	service._on_purchases({"response_code": 0, "purchases": [{"product_ids": ["remove_ads"], "package_name": MonetizationConfig.PACKAGE, "purchase_state": 2}]})
	suite.check(not service.has_plus() and service.state == "pending" and not service.can_purchase(), "pending purchase blocks duplicate payment without granting")
	service._nonce = "b".repeat(64)
	service._token = "fixture-token"
	service._verified(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(receipt).to_utf8_buffer())
	suite.check(service.has_plus() and service.state == "purchased", "only a valid server response grants native Plus")
	service.restore()
	service._purchase_revision += 1
	service._nonce = "b".repeat(64)
	service._token = "fixture-token"
	service._on_query({"response_code": 0, "purchases": []})
	suite.check(service.has_plus() and service._requery, "old restore snapshot cannot erase a newer purchase update")
	service._cancel_verification()
	service._on_query({"response_code": 2})
	suite.check(service.has_plus(), "store outage retains signed offline entitlement")
	service._nonce = "b".repeat(64)
	service._token = "different-token"
	service._verified(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(receipt).to_utf8_buffer())
	suite.check(service.state == "failure", "signed response for another token is rejected")
	service._on_query({"response_code": 0, "purchases": []})
	suite.check(not service.has_plus() and service._receipt.is_empty(), "authoritative empty restore revokes Plus and clears its cache")
	service._nonce = ""
	service._verified(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(receipt).to_utf8_buffer())
	suite.check(not service.has_plus(), "late verification response after revocation cannot restore ownership")
	service._on_products({"response_code": 0, "product_details": []})
	suite.check(service.product_price.is_empty() and not service.can_purchase(), "unavailable product never falls back to hardcoded USD pricing")
	var access: ReviewAccess = ReviewAccess.new()
	access.verifier = verifier
	access.cache_path = service.cache_path + ".access"
	service.access = access
	service.add_child(access)
	access.changed.connect(service._refresh_cached)
	access.busy = true
	access._nonce = "b".repeat(64)
	access._token_hash = str(fixture.access_code).sha256_text()
	access._completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(fixture.access_receipt).to_utf8_buffer())
	suite.check(service.has_plus() and access.active, "server-signed access code unlocks the same Plus entitlement")
	service._on_query({"response_code": 0, "purchases": []})
	suite.check(service.has_plus(), "empty Play ownership does not erase a separately verified access grant")
	var restored_access: ReviewAccess = ReviewAccess.new()
	restored_access.verifier = verifier
	restored_access.cache_path = access.cache_path
	restored_access.initialize()
	suite.check(restored_access.active, "review access survives restart through signed cache without storing the code")
	suite.check(not FileAccess.get_file_as_string(access.cache_path).contains(str(fixture.access_code)), "review code is never persisted in cache")
	var review_claims: Dictionary = JSON.parse_string(Marshalls.base64_to_raw(fixture.access_receipt.payload).get_string_from_utf8())
	restored_access._last_time = int(review_claims.expires_at)
	restored_access.refresh()
	suite.check(not restored_access.active, "review receipt expires and needs the reusable code again")
	restored_access.free()
	access.clear()
	suite.check(not service.has_plus(), "clearing review access restores the free game for review")
	access.busy = true
	access._nonce = "c".repeat(64)
	access._token_hash = str(fixture.access_code).sha256_text()
	access._completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(fixture.access_receipt).to_utf8_buffer())
	suite.check(not access.active, "replayed access response cannot grant on a different request")
	access.busy = true
	access._nonce = "b".repeat(64)
	access._token_hash = "fixture-token".sha256_text()
	access._completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(receipt).to_utf8_buffer())
	suite.check(not access.active, "a purchase receipt cannot be substituted for review access")
	service._receipt = receipt
	service._refresh_cached()
	access.clear()
	suite.check(service.has_plus(), "removing code access preserves purchased Plus")
	service.config.production = false
	service.product_available = true
	service.purchase()
	suite.check(service.state == "disabled" and sdk.purchases == 1, "development adapter cannot charge even with injected product information")

	var consent: NativeConsent = NativeConsent.new()
	var ump: UmpStub = UmpStub.new()
	consent.production = true
	consent.ump = ump
	var ads: AdsService = AdsService.new()
	consent.permission_changed.connect(ads.set_consent_allowed)
	consent.request_update()
	consent.request_update()
	suite.check(ump.requests == 1 and not ads.can_request(), "consent refresh blocks requests and prevents duplicate forms")
	consent._production_updated(true, true, "")
	suite.check(ads.can_request() and consent.privacy_options_required, "actual UMP permission enables ads and exposes privacy choices")
	consent.show_privacy_options()
	suite.check(ump.shows == 1 and not ads.can_request(), "changing privacy choices invalidates ad permission while the form is open")
	consent._production_updated(false, true, "Unavailable")
	suite.check(not ads.can_request(), "consent failure cannot bypass permission")
	consent._production_updated(true, false, "Refresh unavailable")
	suite.check(ads.can_request() and not consent.privacy_options_required, "UMP can preserve valid prior permission when a refresh fails")
	ads.set_ad_free(true)
	consent._production_updated(true, true, "")
	suite.check(not ads.can_request(), "UMP callback cannot re-enable ads for Plus")
	consent.free()
	ads.free()
	service.queue_free()
	DirAccess.remove_absolute("user://test_play_entitlement.json")
	DirAccess.remove_absolute("user://test_play_installation.txt")
	DirAccess.remove_absolute("user://test_play_entitlement.json.access")
