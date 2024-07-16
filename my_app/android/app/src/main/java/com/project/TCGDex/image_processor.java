package com.project.TCGDex;

import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;
import java.util.ArrayList;
import java.util.List;

public class ImagePreprocessor {

    public Mat fourPointTransform(Mat image, Point[] pts) {
        Point[] rect = orderPoints(pts);
        Point tl = rect[0];
        Point tr = rect[1];
        Point br = rect[2];
        Point bl = rect[3];

        double widthA = distance(br, bl);
        double widthB = distance(tr, tl);
        double maxWidth = Math.max(widthA, widthB);

        double heightA = distance(tr, br);
        double heightB = distance(tl, bl);
        double maxHeight = Math.max(heightA, heightB);

        MatOfPoint2f src = new MatOfPoint2f(tl, tr, br, bl);
        MatOfPoint2f dst = new MatOfPoint2f(
            new Point(0, 0),
            new Point(maxWidth - 1, 0),
            new Point(maxWidth - 1, maxHeight - 1),
            new Point(0, maxHeight - 1)
        );

        Mat M = Imgproc.getPerspectiveTransform(src, dst);
        Mat warped = new Mat();
        Imgproc.warpPerspective(image, warped, M, new Size(maxWidth, maxHeight));

        return warped;
    }

    private Point[] orderPoints(Point[] pts) {
        Point[] rect = new Point[4];
        double[] s = new double[pts.length];
        double[] diff = new double[pts.length];

        for (int i = 0; i < pts.length; i++) {
            s[i] = pts[i].x + pts[i].y;
            diff[i] = pts[i].x - pts[i].y;
        }

        rect[0] = pts[minIndex(s)];
        rect[2] = pts[maxIndex(s)];
        rect[1] = pts[minIndex(diff)];
        rect[3] = pts[maxIndex(diff)];

        return rect;
    }

    private double distance(Point p1, Point p2) {
        return Math.sqrt(Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2));
    }

    private int minIndex(double[] array) {
        int minIndex = 0;
        for (int i = 1; i < array.length; i++) {
            if (array[i] < array[minIndex]) {
                minIndex = i;
            }
        }
        return minIndex;
    }

    private int maxIndex(double[] array) {
        int maxIndex = 0;
        for (int i = 1; i < array.length; i++) {
            if (array[i] > array[maxIndex]) {
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    public Mat detectEdges(Mat img) {
        Imgproc.cvtColor(img, img, Imgproc.COLOR_BGR2GRAY);
        Imgproc.GaussianBlur(img, img, new Size(5, 5), 0);
        Mat edges = new Mat();
        Imgproc.Canny(img, edges, 50, 200);
        return edges;
    }

    public Mat extractCard(Mat image) {
        Mat edged = detectEdges(image.clone());

        // Convert to grayscale
        Mat gray = new Mat();
        Imgproc.cvtColor(image, gray, Imgproc.COLOR_BGR2GRAY);

        // Thresholding
        Mat thresh = new Mat();
        Imgproc.threshold(gray, thresh, 190, 255, Imgproc.THRESH_BINARY);

        // Find contours
        List<MatOfPoint> contours = new ArrayList<>();
        Mat hierarchy = new Mat();
        Imgproc.findContours(thresh, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE);
        contours.sort((c1, c2) -> Double.compare(Imgproc.contourArea(c2), Imgproc.contourArea(c1)));

        // Get the largest contour
        MatOfPoint largestContour = contours.get(0);
        MatOfPoint2f hull = new MatOfPoint2f();
        Imgproc.convexHull(new MatOfPoint2f(largestContour.toArray()), hull);

        // Approximate polygon
        MatOfPoint2f approx = new MatOfPoint2f();
        double epsilon = 0.02 * Imgproc.arcLength(hull, true);
        Imgproc.approxPolyDP(hull, approx, epsilon, true);

        // Transform the perspective to get a top-down view of the card
        return fourPointTransform(image, approx.toArray());
    }

    public Mat[] isolateRegions(Mat image) {
        Mat cardImage = extractCard(image);
        Size standardSize = new Size(600, 825);
        Mat normalizedImage = new Mat();
        Imgproc.resize(cardImage, normalizedImage, standardSize);

        // Define the regions
        Rect nameRegionRect = new Rect(5, 0, 395, 90);
        Rect hpRegionRect = new Rect(400, 0, 200, 90);
        Rect moveRegionRect = new Rect(10, 420, 580, 310);
        Rect setSymbolRegionRect = new Rect(10, 730, 580, 95);

        Mat nameRegion = new Mat(normalizedImage, nameRegionRect);
        Mat hpRegion = new Mat(normalizedImage, hpRegionRect);
        Mat moveRegion = new Mat(normalizedImage, moveRegionRect);
        Mat setSymbolRegion = new Mat(normalizedImage, setSymbolRegionRect);

        return new Mat[]{nameRegion, hpRegion, moveRegion, setSymbolRegion};
    }
}
