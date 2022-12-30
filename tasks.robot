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

#Robot shouldn't take a screenshot, whenever the order website misbehaves
Library             RPA.Browser.Playwright    run_on_failure=None
Library             RPA.PDF
Library             RPA.Robocorp.Vault
Library             RPA.HTTP
Library             RPA.Tables


*** Variables ***
${orders_file_path}     ${OUTPUT_DIR}/downloads/orders.csv
${retry}                3x
${retry_interval}       2s


*** Tasks ***
Order Robots
    ${link_orders}=    Read Order Link from Vault
    Download Orders File
    Open Browser on Page    ${link_orders}
    Deal with Popup
    Fill out Order Form
    Preview the Robot
    Try to place Order
    ${screenshot}=    Save Screenshot of Preview
    ${pdf}=    Save PDF of receipt
    Embed Robot Screenshot into PDF of receipt    ${screenshot}    ${pdf}
#    [Teardown]    Log out and close Browser


*** Keywords ***
Read Order Link from Vault
    ${secret}=    Get Secret    robots
    RETURN    ${secret}[link_robot_orders]

Download Orders File
    RPA.HTTP.Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    ${orders_file_path}
    ...    overwrite=True

Open Browser on Page
    [Arguments]    ${url}
    #show GUI for Testing purposes
    Open Browser    ${url}    pause_on_failure=False
    #no GUI for Production
#    New Page    ${url}
    Set Browser Timeout    3s

Deal with Popup
    Click    text=OK

Open File and Loop Through Orders
    ${orders_table}=    Read table from CSV    ${orders_file_path}

Fill out Order Form
    #Head
    Select Options By    id=head    index    2
    #Body
    Check Checkbox    id=id-body-3
    #Legs
    Fill Text    //div[3]/input    2
    #Address
    Fill Text    id=address    meineAdresse

Preview the Robot
    Click    id=preview

Try to place Order
    Wait Until Keyword Succeeds    ${retry}    ${retry_interval}    Place Order and check that receipt is shown

Place Order and check that receipt is shown
    Click    id=order
    Wait For Elements State    id=receipt

Save Screenshot of Preview
    ${screenshot}=    Take Screenshot    filename=preview    selector=id=robot-preview-image
    RETURN    ${screenshot}

Save PDF of receipt
    ${receipt_html}=    Get Property    id=receipt    innerHTML
    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}/receipt.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}
    RETURN    ${pdf_path}

Embed Robot Screenshot into PDF of receipt
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}    ${pdf}
