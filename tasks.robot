*** Settings ***
Documentation       Robot to complete robocorp certificate level II
...                 and order a Robot from RobotsparepartsInc using human Input to get a list of POs
...                 and place these orders
...
...                 RULES
...
...                 use the orders file and complete all the orders in the file.
...                 Only the robot is allowed to get the orders file.
...                 The robot should save each order HTML receipt as a PDF file.
...                 The robot should save a screenshot of each of the ordered robots.
...                 The robot should embed the screenshot of the robot to the PDF receipt.
...                 The robot should create a ZIP archive of the PDF receipts (one zip archive that contains all the PDF files)
...                 -- Store the archive in the output directory.
...                 The robot should complete all the orders even when there are technical failures with the robot order website.
...                 The robot should read some data from a local vault, NO CREDENTIALS.
...                 The robot should use an assistant to ask some input from the human user, and then use that input some way.
...                 The robot should be available in public GitHub repository.
...                 Store the local vault file in the robot project repository so that it does not require manual setup.
...                 It should be possible to get the robot from the public GitHub repository and run it without manual setup.

Library             RPA.Browser
Library             RPA.PDF


*** Tasks ***
Erste Aufgabe


*** Keywords ***
Erste Aufgabe
    Log    hello world
