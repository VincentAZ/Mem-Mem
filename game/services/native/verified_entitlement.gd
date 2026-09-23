class_name VerifiedEntitlement
extends RefCounted
## Offline access is bounded by a server-signed receipt, never a saved ownership flag.
const MAX_AGE: int = 7 * 24 * 60 * 60
var public_key: String = ""
var device_id: String = ""

func claims(receipt: Dictionary, now: int, nonce: String = "") -> Dictionary:
	var payload: String = str(receipt.get("payload", ""))
	var signature: String = str(receipt.get("signature", ""))
	if payload.is_empty() or payload.length() > 8192 or signature.is_empty() or public_key.is_empty():
		return {}
	var key: CryptoKey = CryptoKey.new()
	if key.load_from_string(public_key, true) != OK:
		return {}
	var raw: PackedByteArray = Marshalls.base64_to_raw(payload)
	var hash: HashingContext = HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(raw)
	if not Crypto.new().verify(HashingContext.HASH_SHA256, hash.finish(), Marshalls.base64_to_raw(signature), key):
		return {}
	var parsed: Variant = JSON.parse_string(raw.get_string_from_utf8())
	if not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed
	if data.get("version") != 1 or data.get("package") != MonetizationConfig.PACKAGE or data.get("product") != BillingService.REMOVE_ADS or data.get("device") != device_id:
		return {}
	if not nonce.is_empty() and data.get("nonce") != nonce:
		return {}
	var issued: int = int(data.get("issued_at", 0))
	var expires: int = int(data.get("expires_at", 0))
	if issued <= 0 or issued > now + 300 or expires <= now or expires <= issued or expires - issued > MAX_AGE:
		return {}
	if not data.get("status") in ["active", "pending", "revoked"]:
		return {}
	return data
