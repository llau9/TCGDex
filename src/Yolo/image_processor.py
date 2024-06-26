import cv2
import numpy as np
import matplotlib.pyplot as plt
import math
from collections import defaultdict
import sys
import os

class ImagePreprocessor:

    @staticmethod
    def order_points(pts):
        # Initial ordering of points
        rect = np.zeros((4, 2), dtype="float32")
        s = pts.sum(axis=1)
        rect[0] = pts[np.argmin(s)]
        rect[2] = pts[np.argmax(s)]
        diff = np.diff(pts, axis=1)
        rect[1] = pts[np.argmin(diff)]
        rect[3] = pts[np.argmax(diff)]
        
        # Now we check the distances between points. If the points that are supposed
        # to be the top and bottom are actually longer than the sides, swap them.

        # Calculate side lengths
        width_top = np.sqrt(((rect[1][0] - rect[0][0]) ** 2) + ((rect[1][1] - rect[0][1]) ** 2))
        width_bottom = np.sqrt(((rect[3][0] - rect[2][0]) ** 2) + ((rect[3][1] - rect[2][1]) ** 2))
        height_left = np.sqrt(((rect[0][0] - rect[3][0]) ** 2) + ((rect[0][1] - rect[3][1]) ** 2))
        height_right = np.sqrt(((rect[1][0] - rect[2][0]) ** 2) + ((rect[1][1] - rect[2][1]) ** 2))

        # Find which are the shorter sides and ensure they are the top and bottom
        if (width_top + width_bottom) > (height_left + height_right):
            # It means the card is rotated 90 degrees to the left (counter-clockwise)
            # So we need to shift the order to the right to correct this
            rect = np.roll(rect, -1, axis=0)

        return rect

    def four_point_transform(self, image, pts):
        rect = self.order_points(pts)
        (tl, tr, br, bl) = rect

        # Compute the width and height of the new image
        widthA = np.sqrt(((br[0] - bl[0]) ** 2) + ((br[1] - bl[1]) ** 2))
        widthB = np.sqrt(((tr[0] - tl[0]) ** 2) + ((tr[1] - tl[1]) ** 2))
        maxWidth = max(int(widthA), int(widthB))
        heightA = np.sqrt(((tr[0] - br[0]) ** 2) + ((tr[1] - br[1]) ** 2))
        heightB = np.sqrt(((tl[0] - bl[0]) ** 2) + ((tl[1] - bl[1]) ** 2))
        maxHeight = max(int(heightA), int(heightB))

        # The destination points are the points where we map the original points to
        dst = np.array([
            [0, 0],
            [maxWidth - 1, 0],
            [maxWidth - 1, maxHeight - 1],
            [0, maxHeight - 1]
        ], dtype="float32")

        # Compute the perspective transform matrix and then apply it
        M = cv2.getPerspectiveTransform(rect, dst)
        warped = cv2.warpPerspective(image, M, (maxWidth, maxHeight))

        # Return the warped image
        return warped


    @staticmethod
    def segment_by_angle_kmeans(lines, k=2, **kwargs):
        default_criteria_type = cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER
        criteria = kwargs.get('criteria', (default_criteria_type, 10, 1.0))
        flags = kwargs.get('flags', cv2.KMEANS_RANDOM_CENTERS)
        attempts = kwargs.get('attempts', 10)
        angles = np.array([line[0][1] for line in lines])
        pts = np.array([[np.cos(2*angle), np.sin(2*angle)]
                   for angle in angles], dtype=np.float32)
        

        labels, centers = cv2.kmeans(pts, k, None, criteria, attempts, flags)[1:]
        labels = labels.reshape(-1)

        segmented = defaultdict(list)
        for i, line in zip(range(len(lines)), lines):
            segmented[labels[i]].append(line)

        segmented = list(segmented.values())

        return segmented

    @staticmethod
    def intersection(line1, line2):
        rho1, theta1 = line1[0]
        rho2, theta2 = line2[0]
        A = np.array([[np.cos(theta1), np.sin(theta1)], [np.cos(theta2), np.sin(theta2)]])
        b = np.array([[rho1], [rho2]])
        x0, y0 = np.linalg.solve(A, b)

        return [[x0, y0]]

    def segmented_intersections(self, lines):

        intersections = []
        for i, group in enumerate(lines[:-1]):
            for next_group in lines[i+1:]:
                for line1 in group:
                    for line2 in next_group:
                        intersections.append(self.intersection(line1, line2))

        return intersections

    def drawLines(self, img, lines, color=(255, 0, 0)):
        for i in range(0, len(lines)):
            rho = lines[i][0][0]
            theta = lines[i][0][1]
            a = math.cos(theta)
            b = math.sin(theta)
            x0 = a * rho
            y0 = b * rho
            pt1 = (int(x0 + 1000*(-b)), int(y0 + 1000*(a)))
            pt2 = (int(x0 - 1000*(-b)), int(y0 - 1000*(a)))
            cv2.line(img, pt1, pt2, color, 3, cv2.LINE_AA)


    def detect_edge(self, img):
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        img_blurred = cv2.GaussianBlur(img, (5, 5), 0)
        canny = cv2.Canny(img_blurred, 50, 200, None, 3)
        return canny

    def extract_card(self, image):
        img = image
        if img is None:
            raise ValueError("Image not found Canny(blurred_img, 50, 200)or unable to load.")

        edged = self.detect_edge(img.copy())
        
        # Display processed regions
        plt.figure(figsize=(10, 10))
        plt.imshow(cv2.cvtColor(edged, cv2.COLOR_BGR2RGB))
        plt.title('Edges')
        plt.show()

        imgray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        ret, thresh = cv2.threshold(imgray, 190, 255, 0)

        contours, hierarchy = cv2.findContours(thresh, cv2.RETR_EXTERNAL,  cv2.CHAIN_APPROX_SIMPLE)
        sorted_contours = sorted(contours, key=cv2.contourArea, reverse=True)

        largest_item = sorted_contours[0]
        hull = cv2.convexHull(largest_item)
        epsilon = 0.02*cv2.arcLength(hull, True)
        approx = cv2.approxPolyDP(hull, epsilon, True)

        contoured = img.copy()

        cv2.drawContours(contoured, [hull], -1, (255,0,255), 30)
        # Display processed regions
        plt.figure(figsize=(10, 10))
        plt.imshow(cv2.cvtColor(contoured, cv2.COLOR_BGR2RGB))
        plt.title('Lines')
        plt.show()

        warped = self.four_point_transform(image, approx.reshape(4, 2))

        plt.figure(figsize=(10, 10))
        plt.imshow(cv2.cvtColor(warped, cv2.COLOR_BGR2RGB))
        plt.title('warped')
        plt.show()

        return warped
            

    def isolate_regions(self, image_path):
        image = cv2.imread(image_path)

         # Display processed regions
        plt.figure(figsize=(10, 10))
        plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
        plt.title('Processed Image with Defined Regions')
        plt.show()


        card_image = self.extract_card(image)

        # Display processed regions
        plt.figure(figsize=(10, 10))
        plt.imshow(cv2.cvtColor(card_image, cv2.COLOR_BGR2RGB))
        plt.title('Processed Image with Defined Regions')
        plt.show()


        standard_size = (600, 825)  # Example size, adjust as needed
        try:
            normalized_image = cv2.resize(card_image, standard_size)
        except cv2.error as e:
            print(f"Error resizing image: {e}")
            return None, None, None, None

        name_region_coords = (5, 0, 400, 90)
        hp_region_coords = (400, 0, 600, 90)
        move_region_coords = (10, 420, 590, 730)

        name_region = normalized_image[0:90, 5:400]
        hp_region = normalized_image[0:90, 400:600]
        move_region = normalized_image[420:730, 10:590]

        cv2.rectangle(normalized_image, name_region_coords[:2], name_region_coords[2:], (255, 0, 0), 2)
        cv2.rectangle(normalized_image, hp_region_coords[:2], hp_region_coords[2:], (0, 255, 0), 2)
        cv2.rectangle(normalized_image, move_region_coords[:2], move_region_coords[2:], (0, 0, 255), 2)

        return normalized_image, name_region, hp_region, move_region