using namespace OpenQA.Selenium

#---------------------------------------------------------------------
# PGM     : katsushika_tennis2.ps1
# COMMENT : テニスコート空き状況検索(休日)
#---------------------------------------------------------------------
# History : Create by aldehyde (2023/1/7)
#---------------------------------------------------------------------
$BASE_DIR = $PSScriptRoot

$FileName = $FileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
#$LOGF    = "${AplPath}\log\${FileName}.log"

if (Test-Path (Join-Path $BASE_DIR ".env")) {
    .(Join-Path $BASE_DIR "Load-Env.ps1")
}

.(Join-Path $BASE_DIR "KTSK_ENV.ps1")
.(Join-Path $BASE_DIR "function.ps1")

$driver = Create-EdgeDriver

$driver.Navigate().GoToURL("https://rsv.shisetsu.city.katsushika.lg.jp/katsushika/web/index.jsp")

$driver.ExecuteScript("javaScript:canLogin()")

$driver.ExecuteScript("javascript:doPpsdSearchAction((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchPpsdAction)")

$driver.ExecuteScript("javascript:sendPpsdCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchPpsAction, '200','2')")

$driver.ExecuteScript("javascript:doTransInstSrchBuildAction((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchBuildAction, '200' , '200600')")


$emptyCoats = New-Object 'System.Collections.Generic.List[PSObject]'

#１ヶ月以内の休日リスト
$holidays = createHolidayList

#調べるコートのリスト
$CoatKeys = $COAT_URL_HASH.Keys

try{

    #///////////////空きコートの検索////////////////////
    foreach ( $CoatKey in $CoatKeys ){
        $CoatKey
        
        $URL = $COAT_URL_HASH[$CoatKey]

        $driver.ExecuteScript($URL)
        Start-Random-Sleep
        
        foreach ( $holiday in $holidays ){
        
            "対象日付：" + ${holiday}.ToString("yyyy-MM-dd")
        
            $y = $holiday.ToString("yyyy")
            $m = $holiday.ToString("MM")
            $d = $holiday.ToString("dd")
            
            $URL = "javascript:selectDay((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWInstSrchVacantWAllAction, 1, ${y}, ${m}, ${d})"
            $driver.ExecuteScript($URL)
            Start-Random-Sleep
            
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
            $driver.ExecuteScript($URL)
            Start-Random-Sleep
                    
        }
        
        #コート選択画面に戻る
        $URL = "javascript:doAction((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWInstSrchMonthVacantBackAction);"
        $driver.ExecuteScript($URL)   
        Start-Random-Sleep
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

■葛飾区公共施設予約システム
https://rsv.shisetsu.city.katsushika.lg.jp/web/menu.jsp
(10009312/1231)
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
