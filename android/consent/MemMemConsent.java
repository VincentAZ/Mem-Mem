package io.github.vincentaz.memmem;

import android.app.Activity;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.Collections;
import java.util.Set;

/** Exposes UMP's permission and privacy APIs missing from the pinned ad wrapper. */
public final class MemMemConsent extends GodotPlugin {
    private boolean busy;
    public MemMemConsent(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "MemMemConsent"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(new SignalInfo("consent_updated", Boolean.class, Boolean.class, String.class));
    }
    private void finish(String error) {
        Activity activity = getActivity();
        if (activity == null) return;
        ConsentInformation info = UserMessagingPlatform.getConsentInformation(activity);
        busy = false;
        emitSignal("consent_updated", info.canRequestAds(),
            info.getPrivacyOptionsRequirementStatus() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED,
            error);
    }
    @UsedByGodot public void request_update(boolean underAge) {
        Activity activity = getActivity();
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (busy) return;
            busy = true;
            ConsentInformation info = UserMessagingPlatform.getConsentInformation(activity);
            ConsentRequestParameters params = new ConsentRequestParameters.Builder()
                .setTagForUnderAgeOfConsent(underAge).build();
            info.requestConsentInfoUpdate(activity, params,
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity,
                    error -> finish(error == null ? "" : "Privacy choices could not be loaded. Please try again.")),
                error -> finish("Privacy choices are temporarily unavailable. Please try again."));
        });
    }
    @UsedByGodot public void show_privacy_options() {
        Activity activity = getActivity();
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (busy) return;
            busy = true;
            UserMessagingPlatform.showPrivacyOptionsForm(activity,
                error -> finish(error == null ? "" : "Privacy choices could not be opened. Please try again."));
        });
    }
}
