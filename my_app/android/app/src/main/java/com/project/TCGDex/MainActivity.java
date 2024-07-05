package com.project.TCGDex;

import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import net.tcgdex.sdk.TCGdex;
import net.tcgdex.sdk.models.Card;
import net.tcgdex.sdk.models.CardResume;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example/tcgdex";
    private static final String TAG = "MainActivity";
    private ExecutorService executorService = Executors.newSingleThreadExecutor();
    private List<Map<String, String>> cardData = new ArrayList<>();

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        loadCSVData();
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    switch (call.method) {
                        case "fetchRandomCardImage":
                            fetchRandomCardImage(result);
                            break;
                        case "fetchCardDetails":
                            String cardId = call.argument("cardId");
                            fetchCardDetails(cardId, result);
                            break;
                        case "searchCards":
                            String name = call.argument("name");
                            Log.d(TAG, "Search name: " + name);
                            searchCards(name, result);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                }
            );
    }

    private void loadCSVData() {
        try (InputStream inputStream = getAssets().open("cardAttributes.csv");
             BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream))) {
            String line;
            String[] headers = reader.readLine().split(",");
            Log.d(TAG, "CSV Headers: " + java.util.Arrays.toString(headers));

            while ((line = reader.readLine()) != null) {
                String[] values = line.split(",", -1);
                if (values.length != headers.length) {
                    Log.w(TAG, "Skipping malformed line: " + line);
                    continue;
                }
                Map<String, String> card = new HashMap<>();
                for (int i = 0; i < headers.length; i++) {
                    card.put(headers[i], values[i]);
                }
                cardData.add(card);
                Log.d(TAG, "Card added: " + card.toString());
            }
            Log.d(TAG, "CSV data loaded successfully, total cards: " + cardData.size());
        } catch (Exception e) {
            Log.e(TAG, "Error loading CSV data", e);
        }
    }

    private void fetchRandomCardImage(MethodChannel.Result result) {
        Future<?> future = executorService.submit(() -> {
            TCGdex api = new TCGdex("en");
            try {
                Log.d(TAG, "Fetching cards...");
                CardResume[] cardResumes = api.fetchCards();

                if (cardResumes.length == 0) {
                    Log.e(TAG, "No cards found.");
                    result.error("UNAVAILABLE", "No cards found.", null);
                    return;
                }

                Random rand = new Random();
                int randomIndex = rand.nextInt(cardResumes.length);
                CardResume randomCard = cardResumes[randomIndex];

                String baseUrl = randomCard.getImage();
                if (baseUrl == null || baseUrl.isEmpty()) {
                    Log.e(TAG, "Selected card has no base image URL.");
                    result.error("UNAVAILABLE", "Card image not available.", null);
                    return;
                }

                String imageUrl = baseUrl + "/high.png";
                result.success(imageUrl);
            } catch (Exception e) {
                Log.e(TAG, "Error fetching card image: ", e);
                result.error("UNAVAILABLE", "Error fetching card image.", e);
            }
        });
    }

    private void fetchCardDetails(String cardId, MethodChannel.Result result) {
        Future<?> future = executorService.submit(() -> {
            TCGdex api = new TCGdex("en");
            try {
                Log.d(TAG, "Fetching card details for ID: " + cardId);
                Card card = api.fetchCard(cardId);

                if (card == null) {
                    Log.e(TAG, "Card not found.");
                    result.error("UNAVAILABLE", "Card not found.", null);
                    return;
                }

                Map<String, Object> cardDetails = new HashMap<>();
                cardDetails.put("id", card.getId());
                cardDetails.put("name", card.getName());
                cardDetails.put("image", card.getImage());

                result.success(cardDetails);
            } catch (Exception e) {
                Log.e(TAG, "Error fetching card details: ", e);
                result.error("UNAVAILABLE", "Error fetching card details.", e);
            }
        });
    }

    private void searchCards(String name, MethodChannel.Result result) {
        Future<?> future = executorService.submit(() -> {
            List<String> candidateIds = new ArrayList<>();
            for (Map<String, String> card : cardData) {
                String cardName = card.get("name").toLowerCase();
                if (cardName.contains(name.toLowerCase())) {
                    candidateIds.add(card.get("id"));
                }
            }
            result.success(candidateIds);
        });
    }
}
