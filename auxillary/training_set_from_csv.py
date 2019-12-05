#!/usr/bin/python3
# -*- coding: utf-8 -*-
import os, sys, argparse, csv 
from PIL import Image
#parse the arguments 
parser = argparse.ArgumentParser(description='Generate ocr training set from Lace CSV output') 
parser.add_argument('--imageDir',    action="append",
                   help='Path to directory where source images are found',
                    required=True)
parser.add_argument('--outputDir', default='OCR_training_out',
                   help='Path to directory where output is stored')
parser.add_argument('--csvFile', help='Path to CSV file', required=True,
                    action="append")
parser.add_argument("-v", "--verbose", help="increase output verbosity",
                    default=False,
                    action="store_true")
parser.add_argument("--format", type=str, choices=["jpg", "png", "tif"],
                    default="png",
                    help="set the format of the output images")
args = parser.parse_args()

#Check that the images directories actually exist
for image_dir in args.imageDir:
    if not(os.path.isdir(image_dir)):
           print('Image directory "'+image_dir+'" does not exist.\n\tExiting ...')
           sys.exit(1)

#Check that the csv files actually exist
for csv_file in args.csvFile:
    if not(os.path.isfile(csv_file)):
           print('CSV file "'+csv_file+'" does not exist.\n\tExiting ...')
           sys.exit(1)
#Create the output director if it doesn't exist
try:
    if not os.path.exists(args.outputDir):
        os.makedirs(args.outputDir, exist_ok=True)
except Exception as e:
    print("Error on creating output directory '" + args.outputDir + "':\n\t" +
          str(e) + "\n\tExiting ...")
    sys.exit(1)

if (args.verbose):
    print("Image dir(s):", args.imageDir)
    print("Output dir:", args.outputDir)
    print("CSV file(s):", args.csvFile)

#put all the data in one big list
data = []
for csv_file in args.csvFile:
    with open(csv_file, newline='') as csvfile:
        csvreader = csv.reader(csvfile, delimiter='\t', quotechar='|')
        #for row in csvreader:
        #    print ('$ '.join(row))
        #    print ("#")
        data = data + list(csvreader)

if (args.verbose):
    print(data)

data.sort()
current_image_name = ""
extension = ""
basename = ""
output_base = ""
image_counter = 0
for row in data:
    if len(row) != 3:
        print("The row " + row + "has " + len(row) + " items in it, not 3.\n\tExiting ...")
        sys.exit(1)
    if row[0] != current_image_name:
        #we've changed base images
        image_counter = 0
        current_image_name = row[0]
        print("new image: ", current_image_name)
        extension = os.path.splitext(current_image_name)[1]
        basename = os.path.splitext(current_image_name)[0]
        image_file = ""
        for image_dir in args.imageDir:
            test_image_file = os.path.join(image_dir,row[0])
            if os.path.isfile(test_image_file):
                image_file = test_image_file
                img = Image.open(image_file)
                break
        if image_file == "":
            print("Image file",row[0], "could not be found in directories",
              args.imageDir, " Exiting ...")
            exit(1)

    output_base = basename + '_' + str(image_counter)   
    #prepare the filenames of the text groundtruth file and output image file
    gt_filename = output_base + '.gt.txt'
    image_out_filename = output_base + '.bin.png'
    text_out_path = os.path.join(args.outputDir,gt_filename)
    #output the text gt file
    #TODO Wrap with exception handler, in case the filesystem fills up
    with open(text_out_path, 'w') as the_file:
        the_file.write(row[2])
    #try to find the original image in the directories given
    bbox = row[1].split()
    try:
        area = (int(bbox[0]), int(bbox[1]), int(bbox[2]), int(bbox[3]))
    except Exception as e:
        print("Error on parsing bbox '" + row[1] + "':\n\t" +
          str(e) + "\n\tExiting ...")
        sys.exit(1)
    cropped_img = img.crop(area)
    cropped_img.save(os.path.join(args.outputDir,image_out_filename))
    image_counter = image_counter + 1
