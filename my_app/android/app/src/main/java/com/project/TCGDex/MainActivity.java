package com.project.TCGDex;

import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import net.tcgdex.sdk.TCGdex;
import net.tcgdex.sdk.models.Card;
import net.tcgdex.sdk.models.CardResume;
import net.tcgdex.sdk.models.SetResume;
import com.opencsv.CSVReader;
import com.opencsv.exceptions.CsvException;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
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
    private boolean csvLoaded = false;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    try {
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
                            case "isCSVLoaded":
                                Log.d(TAG, "isCSVLoaded called, returning: " + csvLoaded);
                                result.success(csvLoaded);
                                break;
                            case "fetchAllSetLogos":
                                fetchAllSetLogos(result);
                                break;
                            case "fetchAllSetSymbols":
                                fetchAllSetSymbols(result);
                                break;    
                            default:
                                result.notImplemented();
                                break;
                        }
                    } catch (Exception e) {
                        Log.e(TAG, "Error in MethodChannel call", e);
                        result.error("UNEXPECTED_ERROR", "An unexpected error occurred.", e);
                    }
                }
            );
        loadCSVData();
    }

    private void loadCSVData() {
        executorService.execute(() -> {
            runOnUiThread(() -> Toast.makeText(this, "Loading CSV data...", Toast.LENGTH_SHORT).show());
            try (InputStream inputStream = getAssets().open("cardAttributes.csv");
                 BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
                 CSVReader csvReader = new CSVReader(reader)) {
                 
                String[] headers = csvReader.readNext();
                Log.d(TAG, "CSV Headers: " + Arrays.toString(headers));
                runOnUiThread(() -> Toast.makeText(this, "CSV Headers: " + Arrays.toString(headers), Toast.LENGTH_LONG).show());

                String[] values;
                while ((values = csvReader.readNext()) != null) {
                    if (values.length != headers.length) {
                        runOnUiThread(() -> Toast.makeText(this, "Skipping malformed line", Toast.LENGTH_SHORT).show());
                        Log.d(TAG, "Malformed line: " + Arrays.toString(values));
                        continue;
                    }
                    Map<String, String> card = new HashMap<>();
                    for (int i = 0; i < headers.length; i++) {
                        card.put(headers[i], values[i]);
                    }
                    synchronized (cardData) {
                        cardData.add(card);
                    }
                }
                csvLoaded = true;
                runOnUiThread(() -> Toast.makeText(this, "CSV data loaded successfully, total cards: " + cardData.size(), Toast.LENGTH_LONG).show());
                Log.d(TAG, "CSV data loaded successfully, total cards: " + cardData.size());
            } catch (IOException | CsvException e) {
                Log.e(TAG, "Error reading CSV file", e);
                runOnUiThread(() -> Toast.makeText(this, "Error reading CSV file: " + e.getMessage(), Toast.LENGTH_LONG).show());
            } catch (Exception e) {
                Log.e(TAG, "Unexpected error while loading CSV", e);
                runOnUiThread(() -> Toast.makeText(this, "Unexpected error while loading CSV: " + e.getMessage(), Toast.LENGTH_LONG).show());
            }
        });
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

                String baseUrl = card.getImage();
                if (baseUrl == null || baseUrl.isEmpty()) {
                    Log.e(TAG, "Card image URL not found.");
                    cardDetails.put("image", "");
                } else {
                    String imageUrl = baseUrl + "/high.png";
                    cardDetails.put("image", imageUrl);
                }

                Log.d(TAG, "Fetched card details: " + cardDetails);
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
            synchronized (cardData) {
                for (Map<String, String> card : cardData) {
                    String cardName = card.get("name").toLowerCase();
                    if (cardName.contains(name.toLowerCase())) {
                        candidateIds.add(card.get("id"));
                        Log.d(TAG, "Matching card ID: " + card.get("id"));
                    }
                }
            }
            Log.d(TAG, "Search results: " + candidateIds);
            result.success(candidateIds);
        });
    }

    private void fetchAllSetLogos(MethodChannel.Result result) {
        Future<?> future = executorService.submit(() -> {
            TCGdex api = new TCGdex("en");
            try {
                Log.d(TAG, "Fetching all sets...");
                SetResume[] setResumes = api.fetchSets();

                if (setResumes == null || setResumes.length == 0) {
                    Log.e(TAG, "No sets found.");
                    result.error("UNAVAILABLE", "No sets found.", null);
                    return;
                }

                List<String> logoUrls = new ArrayList<>();
                for (SetResume setResume : setResumes) {
                    String baseUrl = setResume.getLogo() + ".png";
                    if (baseUrl != null && !baseUrl.isEmpty()) {
                        logoUrls.add(baseUrl);
                        Log.d(TAG, "Fetched set logo URL: " + baseUrl);
                    }
                }
                result.success(logoUrls);
            } catch (Exception e) {
                Log.e(TAG, "Error fetching set logos: ", e);
                result.error("UNAVAILABLE", "Error fetching set logos.", e);
            }
        });
    }

    private void fetchAllSetSymbols(MethodChannel.Result result) {
        Future<?> future = executorService.submit(() -> {
            TCGdex api = new TCGdex("en");
            try {
                Log.d(TAG, "Fetching all sets...");
                SetResume[] setResumes = api.fetchSets();

                if (setResumes == null || setResumes.length == 0) {
                    Log.e(TAG, "No sets found.");
                    result.error("UNAVAILABLE", "No sets found.", null);
                    return;
                }

                List<String> symbolUrls = new ArrayList<>();
                for (SetResume setResume : setResumes) {
                    String baseUrl = setResume.getSymbol() + ".png";
                    if (baseUrl != null && !baseUrl.isEmpty()) {
                        symbolUrls.add(baseUrl);
                        Log.d(TAG, "Fetched set symbol URL: " + baseUrl);
                    }
                }
                result.success(symbolUrls);
            } catch (Exception e) {
                Log.e(TAG, "Error fetching set symbols: ", e);
                result.error("UNAVAILABLE", "Error fetching set symbols.", e);
            }
        });
    }
}
