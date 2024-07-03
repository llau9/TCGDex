package com.project.TCGDex;

import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import net.tcgdex.sdk.TCGdex;
import net.tcgdex.sdk.models.CardResume;
import java.util.List;
import java.util.ArrayList;
import java.util.Random;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example/tcgdex";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("fetchRandomCardImage")) {
                        String cardImage = fetchRandomCardImage();
                        if (cardImage != null) {
                            result.success(cardImage);
                        } else {
                            result.error("UNAVAILABLE", "Card image not available.", null);
                        }
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }

    private String fetchRandomCardImage() {
        TCGdex api = new TCGdex("en");
        try {
            CardResume[] cardResumes = api.fetchCards();
            if (cardResumes.length == 0) {
                return null;
            }
            Random rand = new Random();
            int randomIndex = rand.nextInt(cardResumes.length);
            return cardResumes[randomIndex].getImage();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
