#検索コート（休日）
$COAT_URL_HASH = @{
    "奥戸総スポ" = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '500700')"
    #"水元"        = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '500930')"
    #"東金町"       = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '501700')"
    "渋江公園"                 = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '501800')"
    "小菅東"       = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '501900')"
    "上千葉"         = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '502000')"
    "にいじゅく"     = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '503200')"
}

#検索コート（平日）
$COAT_URL_HASH2 = @{
    #"奥戸総スポ" = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '500700')"
    #"水元"        = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '500930')"
    #"東金町"       = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '501700')"
    #"渋江公園"                 = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '501800')"
    #"小菅東"       = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '501900')"
    #"上千葉"         = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '502000')"
    "にいじゅく"     = "javascript:sendBldCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchInstAction, '503200')"
}


$WEB_DRIVER = Join-Path $BASE_DIR "WebDriver.dll"

$edgeDriverCommand = Get-Command msedgedriver.exe -ErrorAction SilentlyContinue

if ($edgeDriverCommand) {
    # GitHub Actionsなど、PATHにmsedgedriver.exeがある場合
    $EDGE_DRIVER_DIR = Split-Path $edgeDriverCommand.Source
} else {
    # ローカル確認用：bin配下のmsedgedriver.exeを使う
    $EDGE_DRIVER_DIR = $BASE_DIR
}

$EDGE_APP = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

#LINE送信
$LINE_TOKEN = $env:LINE_TOKEN
$LINE_USER_ID = $env:LINE_USER_ID

#メール送信(Gmail)
$MAIL_USER     = $env:MAIL_USER
$MAIL_PASS     = $env:MAIL_PASS
$MAIL_FROM     = $env:MAIL_FROM
$MAIL_TO     = $env:MAIL_TO
$SMTP_HOST = "smtp.gmail.com"
$SMTP_PORT = "587"
