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
                    if (call.method.equals("fetchRandomCardImage")) {
                        fetchRandomCardImage(result);
                    } else if (call.method.equals("fetchCardDetails")) {
                        String cardId = call.argument("cardId");
                        fetchCardDetails(cardId, result);
                    } else if (call.method.equals("searchCards")) {
                        String name = call.argument("name");
                        String set = call.argument("set");
                        String series = call.argument("series");
                        String artist = call.argument("artist");
                        searchCards(name, set, series, artist, result);
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }

    private void loadCSVData() {
        try {
            InputStream inputStream = getAssets().open("Backend/PokemonCards/cardAttributes/cardAttributes.csv");
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
            String line;
            String[] headers = reader.readLine().split(",");
            while ((line = reader.readLine()) != null) {
                String[] values = line.split(",");
                Map<String, String> card = new HashMap<>();
                for (int i = 0; i < headers.length; i++) {
                    card.put(headers[i], values[i]);
                }
                cardData.add(card);
            }
            reader.close();
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

    private void fetchCardDetails(String cardId, MethodChannel.Result result) {
        Future<?> future = executorService.submit(() -> {
            TCGdex api = new TCGdex("en");
            try {
                Log.d(TAG, "Fetching card details for ID: " + cardId);
                Card card = api.getCard(cardId);

                if (card == null) {
                    Log.e(TAG, "Card not found.");
                    result.error("UNAVAILABLE", "Card not found.", null);
                    return;
                }

                result.success(card.getName()); // Adjust this to return the required details
            } catch (Exception e) {
                Log.e(TAG, "Error fetching card details: ", e);
                result.error("UNAVAILABLE", "Error fetching card details.", e);
            }
        });
    }

    private void searchCards(String name, String set, String series, String artist, MethodChannel.Result result) {
        Future<?> future = executorService.submit(() -> {
            List<String> candidateIds = new ArrayList<>();
            for (Map<String, String> card : cardData) {
                boolean matches = true;
                if (name != null && !card.get("name").contains(name)) {
                    matches = false;
                }
                if (set != null && !card.get("set").contains(set)) {
                    matches = false;
                }
                if (series != null && !card.get("series").contains(series)) {
                    matches = false;
                }
                if (artist != null && !card.get("artist").contains(artist)) {
                    matches = false;
                }
                if (matches) {
                    candidateIds.add(card.get("id"));
                }
            }
            result.success(candidateIds);
        });
    }
}
