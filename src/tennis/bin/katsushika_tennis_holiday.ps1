using namespace OpenQA.Selenium

#---------------------------------------------------------------------
# PGM     : katsushika_tennis2.ps1
# COMMENT : katsushika tennis court check(holiday)
#---------------------------------------------------------------------
$BASE_DIR = $PSScriptRoot

$FileName = $FileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
#$LOGF    = "${AplPath}\log\${FileName}.log"

(Join-Path $BASE_DIR ".env")
if (Test-Path (Join-Path $BASE_DIR ".env")) {
    .(Join-Path $BASE_DIR "Load-Env.ps1") -BaseDir $BASE_DIR
}

.(Join-Path $BASE_DIR "KTSK_ENV.ps1")
.(Join-Path $BASE_DIR "function.ps1")

$driver = Create-EdgeDriver

Open-TopPage $driver

$emptyCoats = New-Object 'System.Collections.Generic.List[PSObject]'

#１ヶ月以内の休日リスト
$holidays = createHolidayList

#調べるコートのリスト
$CoatKeys = $COAT_URL_HASH.Keys

try{

    #///////////////空きコートの検索////////////////////
    foreach ( $CoatKey in $CoatKeys ){
        $CoatKey
        
        Open-CoatCalendar $driver $CoatKey

        foreach ( $holiday in $holidays ){
        
            "対象日付：" + ${holiday}.ToString("yyyy-MM-dd")
            
            $y = $holiday.ToString("yyyy")
            $m = $holiday.ToString("MM")
            $d = $holiday.ToString("dd")
            
            try{

                $URL = "javascript:selectDay((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWInstSrchVacantWAllAction, 1, ${y}, ${m}, ${d})"
                ExecuteScriptWithSleep $driver $URL

                throws "aaaa"

                #imgタグ内にある空きマーク画像の数を数える
                #$emptyImgs = 0

                #空き状況画面のTR要素（YYYY年MM月DD日、テニスコートA面、テニスコートB面...etc）
                $TR_ELEMENTS = $driver.FindElements([By]::XPath("//*[@id='disp']/center/form/center/table/tbody/tr[4]/td/table/tbody/tr/td[1]/table/tbody/tr"))
                #$TR_ELEMENTS = $TR_ELEMENTS[1,2,3,4,5,6,7,8,9] #1行目はヘッダのためカット
                $TR_HEADER = $TR_ELEMENTS[0]
                
                $TR_ELEMENTS = $TR_ELEMENTS[1 .. $TR_ELEMENTS.Count]
                #"TR_ELEMENTS=" + $TR_ELEMENTS.Count
                foreach($TR in $TR_ELEMENTS){
                    $TD_ELEMENTS = $TR.FindElements([By]::TagName("TD"))
                    #"TD_ELEMENTS=" + $TD_ELEMENTS.Count
                    $imgTags = $TD_ELEMENTS.FindElements([By]::TagName("img"))
                    for ($i=0; $i -lt $imgTags.Count; $i++){
                    #$imgTags | %{

                        if($imgTags[$i].GetAttribute("src").Contains("lw_emptybs.gif") -eq "True"){
                            #$emptyImgs = $emptyImgs + 1 

                            $TH_HEADERS = $TR_HEADER.FindElements([By]::TagName("TH"))
                            $TH_HEADERS = $TH_HEADERS[1..$TH_HEADERS.Count] #ヘッダの1列目はYYYY年MM月DD日）

                            $coat = createCoatObject $CoatKey $holiday $TH_HEADERS[$i] $TR
                            $coat
                            $emptyCoats.Add($coat) 

                        }
                    }

                }

                #調べ終わったら元のカレンダー画面に戻ります
                $URL = "javascript:doAction((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWInstSrchVacantBackWAllAction)"
                ExecuteScriptWithSleep $driver $URL
            
            } catch [Exception] {
                "日付処理でエラー。画面を作り直します。"
                "対象コート：$CoatKey"
                "対象日付：" + $holiday.ToString("yyyy-MM-dd")
                $Error[0]

                try {
                    Open-CoatCalendar $driver $CoatKey
                } catch {
                    "画面復旧に失敗しました。ブラウザを作り直します。"
                    $Error[0]

                    try {
                        $driver.Quit()
                    } catch {}

                    $driver = Create-EdgeDriver
                    Open-CoatCalendar $driver $CoatKey
                }
            }
            
        }
        
        #コート選択画面に戻る
        $URL = "javascript:doAction((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWInstSrchMonthVacantBackAction);"
        ExecuteScriptWithSleep $driver $URL
    }
    #///////////////空きコートの検索 end////////////////////

} catch [Exception] {
    $Error[0]

}


#///////////////メール送信対象の選定////////////////////
$Notice_List = @()
$emptyCoats | %{

 #if($_.TimeFrom.Contains("18")){ #18時以降
    $Notice_List += $_
 #}

}
#///////////////メール送信対象の選定////////////////////

if ($Notice_List.Count -gt 0){
#１件以上のコート空きを確認
    
    $BodyCoat = ""    
    foreach($c in $Notice_List){
        #本文用空きコートリスト
        $BodyCoat = $BodyCoat + "`n" + $c.CoatName + "/" + $c.Day + "/" + $c.CoatNo + "/" + $c.TimeFrom + "-" + $c.TimeTo
    }
    
#メール本文テンプレ
$BODY_TAMPLATE = @"
【休日空き状況】

※下記のコートが開いています↓↓
${BodyCoat}

"@

sendLine $BODY_TAMPLATE

#if(-not($res.status -eq "200")){
#    throw $res
#}
 

}

(Get-date -format g) + " 空きコート：" + $Notice_List.Count

$driver.Quit()
$driver = $NULL

[GC]::Collect()

exit 0

trap {
      "★例外エラー：" + (Get-date -format g)
      $Error[0]
      
      #sendLine $Error[0] #LINEは月に200通までしか送れないので節約
      sendErrorMail $Error[0]
      
      $driver.Quit()
      $driver = $NULL

      [GC]::Collect()
      
      exit 1
     }
