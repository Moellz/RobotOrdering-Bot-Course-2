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
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs


*** Variables ***
#switch for debugging and showing browser GUI; 1= Debug mode
${debug}                    0

${csv_file_path}            ${OUTPUT_DIR}/downloads/orders.csv
${receipt_pdf_folder}       ${OUTPUT_DIR}/receipts
${retry}                    5x
${retry_interval}           0.5s


*** Tasks ***
Order Robots
    ${URL_to_order}=    Read Order URL from Vault
    ${orders}=    Get Orders File
    Open Browser on Page    ${URL_to_order}
    FOR    ${order_row}    IN    @{orders}
        Deal with Popup
        Fill out Order Form    ${order_row}
        Preview the Robot
        Try to place Order
        ${screenshot}=    Save Screenshot of Preview    ${order_row}[Order number]
        ${pdf}=    Save PDF of receipt    ${order_row}[Order number]
        Embed Robot Screenshot into PDF of receipt    ${screenshot}    ${pdf}
        Order another Robot
    END
    ZIP receipts and delete individual files


*** Keywords ***
Read Order URL from Vault
    ${secret}=    Get Secret    robots
    RETURN    ${secret}[URL_robot_orders]

Get Orders File
    Add heading    What's the URL for the orders.csv File?
    Add heading    maybe: https://robotsparebinindustries.com/orders.csv    size=Small
    Add text input    URL    label=Enter URL here
    ${result}=    Run dialog    on_top=True

    RPA.HTTP.Download
    ...    ${result.URL}
    ...    ${csv_file_path}
    ...    overwrite=True
    ${table}=    Read table from CSV    ${csv_file_path}    header=True
    RETURN    ${table}

Open Browser on Page
    [Arguments]    ${url}
    IF    ${debug} == 1
        #show GUI for Testing purposes
        Open Browser    ${url}    pause_on_failure=False
    ELSE
        #no GUI for Production
        New Page    ${url}
    END
    #change Browser Timeout from 10s to 3s, so that a misbehaving order website slow down execution too much
    Set Browser Timeout    3s

Deal with Popup
    Click    text=OK

Fill out Order Form
    [Arguments]    ${order}
    #Head
    Select Options By    id=head    index    ${order}[Head]
    #Body
    Check Checkbox    id=id-body-${order}[Head]
    #Legs
    Fill Text    //div[3]/input    ${order}[Legs]
    #Address
    Fill Text    id=address    ${order}[Address]

Preview the Robot
    Click    id=preview

Try to place Order
    Wait Until Keyword Succeeds    ${retry}    ${retry_interval}    Place Order and check that receipt is shown

Place Order and check that receipt is shown
    Click    id=order
    Wait For Elements State    id=receipt    timeout=0.5s

Save Screenshot of Preview
    [Arguments]    ${order_number}
    ${screenshot}=    Take Screenshot    filename=${order_number}    selector=id=robot-preview-image
    RETURN    ${screenshot}

Save PDF of receipt
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Property    id=receipt    innerHTML
    #set pdf_path so that it can be 1. used by Html To Pdf and 2. returned
    ${pdf_path}=    Set Variable    ${receipt_pdf_folder}/${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}
    RETURN    ${pdf_path}

Embed Robot Screenshot into PDF of receipt
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}    ${pdf}

Order another Robot
    Click    id=order-another

ZIP receipts and delete individual files
    Archive Folder With Zip    ${receipt_pdf_folder}    ${OUTPUT_DIR}/receipts.zip
    Remove Directory    ${receipt_pdf_folder}    recursive=True
