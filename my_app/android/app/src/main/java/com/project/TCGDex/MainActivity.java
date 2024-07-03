package com.project.TCGDex;

import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import net.tcgdex.sdk.TCGdex;
import net.tcgdex.sdk.models.CardResume;
import java.util.Random;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example/tcgdex";
    private static final String TAG = "MainActivity";
    private ExecutorService executorService = Executors.newSingleThreadExecutor();

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("fetchRandomCardImage")) {
                        fetchRandomCardImage(result);
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }

    private void fetchRandomCardImage(MethodChannel.Result result) {
        Future<?> future = executorService.submit(() -> {
            TCGdex api = new TCGdex("en");
            try {
                Log.d(TAG, "Fetching cards...");
                CardResume[] cardResumes = api.fetchCards();
                Log.d(TAG, "Number of cards fetched: " + cardResumes.length);

                if (cardResumes.length == 0) {
                    Log.e(TAG, "No cards found.");
                    result.error("UNAVAILABLE", "No cards found.", null);
                    return;
                }

                Random rand = new Random();
                int randomIndex = rand.nextInt(cardResumes.length);
                CardResume randomCard = cardResumes[randomIndex];

                Log.d(TAG, "Random card selected: " + randomCard.getName());

                String baseUrl = randomCard.getImage();
                if (baseUrl == null || baseUrl.isEmpty()) {
                    Log.e(TAG, "Selected card has no base image URL.");
                    result.error("UNAVAILABLE", "Card image not available.", null);
                    return;
                }

                // Construct the final URL with quality and extension
                String imageUrl = baseUrl + "/high.png";
                Log.d(TAG, "Constructed card image URL: " + imageUrl);
                result.success(imageUrl);
            } catch (Exception e) {
                Log.e(TAG, "Error fetching card image: ", e);
                result.error("UNAVAILABLE", "Error fetching card image.", e);
            }
        });
    }
}
