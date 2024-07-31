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
import net.tcgdex.sdk.models.Set;
import net.tcgdex.sdk.models.SetResume;
import net.tcgdex.sdk.models.Serie;
import net.tcgdex.sdk.models.SerieResume;
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
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.Random;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example/tcgdex";
    private static final String TAG = "MainActivity";
    private ExecutorService executorService = Executors.newSingleThreadExecutor();
    private List<Map<String, String>> cardData = new ArrayList<>();
    private boolean csvLoaded = false;
    private TCGdex api;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        api = new TCGdex("en");
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
                                String filters = call.argument("filters");
                                Log.d(TAG, "Search filters: " + filters);
                                searchCards(filters, result);
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
                            case "fetchCardsBySetId":
                                String setId = call.argument("setId");
                                fetchCardsBySetId(setId, result);
                                break;
                            case "fetchSeries":
                                fetchSeries(result);
                                break;
                            case "fetchSerie":
                                String serieId = call.argument("seriesId");
                                fetchSerie(serieId, result);
                                break;
                            case "getSuggestions":
                                String category = call.argument("category");
                                String query = call.argument("query");
                                getSuggestions(category, query, result);
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

                String[] values;
                while ((values = csvReader.readNext()) != null) {
                    if (values.length != headers.length) {
                        Log.d(TAG, "Skipping malformed line: " + Arrays.toString(values));
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
            }
        });
    }

    private void getSuggestions(String category, String query, MethodChannel.Result result) {
        executorService.execute(() -> {
            List<String> suggestions = new ArrayList<>();
            if (csvLoaded && category != null && query != null) {
                for (Map<String, String> card : cardData) {
                    String value = card.get(category);
                    if (value != null && value.toLowerCase().startsWith(query.toLowerCase())) {
                        suggestions.add(value);
                    }
                }
            }
            result.success(suggestions);
        });
    }

    private void fetchRandomCardImage(MethodChannel.Result result) {
        executorService.submit(() -> {
            try {
                Log.d(TAG, "Fetching cards...");
                CardResume[] cardResumes = api.fetchCards();

                if (cardResumes.length == 0) {
                    Log.e(TAG, "No cards found.");
                    result.error("UNAVAILABLE", "No cards found.", null);
                    return;
                }

                Random rand = new Random();
                String imageUrl = null;
                for (int i = 0; i < cardResumes.length; i++) {
                    int randomIndex = rand.nextInt(cardResumes.length);
                    CardResume randomCard = cardResumes[randomIndex];

                    String baseUrl = randomCard.getImage();
                    if (baseUrl != null && !baseUrl.isEmpty()) {
                        imageUrl = baseUrl + "/high.png";
                        break;
                    }
                }

                if (imageUrl == null) {
                    Log.e(TAG, "No card with a valid image URL found.");
                    result.error("UNAVAILABLE", "Card image not available.", null);
                } else {
                    result.success(imageUrl);
                }
            } catch (Exception e) {
                Log.e(TAG, "Error fetching card image: ", e);
                result.error("UNAVAILABLE", "Error fetching card image.", e);
            }
        });
    }

    private void fetchCardDetails(String cardId, MethodChannel.Result result) {
        executorService.submit(() -> {
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

    private void searchCards(String filters, MethodChannel.Result result) {
        executorService.submit(() -> {
            Map<String, String> filterCriteria = parseFilters(filters);
            List<String> candidateIds = new ArrayList<>();
            synchronized (cardData) {
                for (Map<String, String> card : cardData) {
                    boolean matches = true;
                    for (Map.Entry<String, String> filter : filterCriteria.entrySet()) {
                        String key = filter.getKey();
                        String value = filter.getValue();
                        String cardValue = card.get(key);

                        // Check if the card attribute value exists and matches the filter value
                        if (cardValue == null || !cardValue.toLowerCase().contains(value)) {
                            matches = false;
                            break;
                        }
                    }
                    if (matches) {
                        candidateIds.add(card.get("id"));
                    }
                }
            }
            Log.d(TAG, "Search results: " + candidateIds);
            result.success(candidateIds);
        });
    }

    private Map<String, String> parseFilters(String filters) {
        Map<String, String> filterCriteria = new HashMap<>();
        // Updated regex to handle cases with extra spaces and ensure correct parsing
        Pattern pattern = Pattern.compile("\\s*([^:]+?)\\s*:\\s*([^,]+?)\\s*(?:,|$)");
        Matcher matcher = pattern.matcher(filters);
        while (matcher.find()) {
            filterCriteria.put(matcher.group(1).trim().toLowerCase(), matcher.group(2).trim().toLowerCase());
        }
        return filterCriteria;
    }

    private void fetchAllSetLogos(MethodChannel.Result result) {
        executorService.submit(() -> {
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
        executorService.submit(() -> {
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

    private void fetchCardsBySetId(String setId, MethodChannel.Result result) {
        executorService.submit(() -> {
            try {
                Log.d(TAG, "Fetching set for ID: " + setId);
                Set set = api.fetchSet(setId);

                if (set == null) {
                    Log.e(TAG, "Set not found.");
                    result.error("UNAVAILABLE", "Set not found.", null);
                    return;
                }

                List<Map<String, String>> cards = new ArrayList<>();
                for (CardResume card : set.getCards()) {
                    Map<String, String> cardData = new HashMap<>();
                    cardData.put("id", card.getId());
                    cardData.put("name", card.getName());
                    cardData.put("image", card.getImage() + "/high.png");
                    cards.add(cardData);
                }
                result.success(cards);
            } catch (Exception e) {
                Log.e(TAG, "Error fetching cards by set ID: ", e);
                result.error("UNAVAILABLE", "Error fetching cards by set ID.", e);
            }
        });
    }

    private void fetchSeries(MethodChannel.Result result) {
        executorService.submit(() -> {
            try {
                Log.d(TAG, "Fetching all series...");
                SerieResume[] seriesResumes = api.fetchSeries();

                if (seriesResumes == null || seriesResumes.length == 0) {
                    Log.e(TAG, "No series found.");
                    result.error("UNAVAILABLE", "No series found.", null);
                    return;
                }

                List<Map<String, String>> seriesList = new ArrayList<>();
                for (SerieResume serie : seriesResumes) {
                    Map<String, String> serieData = new HashMap<>();
                    serieData.put("id", serie.getId());
                    serieData.put("name", serie.getName());
                    seriesList.add(serieData);
                }
                result.success(seriesList);
            } catch (Exception e) {
                Log.e(TAG, "Error fetching series: ", e);
                result.error("UNAVAILABLE", "Error fetching series.", e);
            }
        });
    }

    private void fetchSerie(String serieId, MethodChannel.Result result) {
        executorService.submit(() -> {
            try {
                Log.d(TAG, "Fetching serie for ID: " + serieId);
                Serie serie = api.fetchSerie(serieId);

                if (serie == null) {
                    Log.e(TAG, "Serie not found.");
                    result.error("UNAVAILABLE", "Serie not found.", null);
                    return;
                }

                List<Map<String, String>> setsList = new ArrayList<>();
                for (SetResume set : serie.getSets()) {
                    Map<String, String> setData = new HashMap<>();
                    setData.put("id", set.getId());
                    setData.put("name", set.getName());
                    setData.put("logo", set.getLogo());
                    setData.put("symbol", set.getSymbol());
                    setsList.add(setData);
                }
                result.success(setsList);
            } catch (Exception e) {
                Log.e(TAG, "Error fetching serie: ", e);
                result.error("UNAVAILABLE", "Error fetching serie.", e);
            }
        });
    }
}
