using namespace OpenQA.Selenium

#---------------------------------------------------------------------
# PGM     : katsushika_tennis2.ps1
# COMMENT : テニスコート空き状況検索(平日)
#---------------------------------------------------------------------
# History : Create by aldehyde (2023/1/7)
#---------------------------------------------------------------------
$AplPath = Split-Path (Split-Path ( & { $myInvocation.ScriptName } ) -parent) -parent
$SHID    = $MyInvocation.MyCommand.Name.substring(0,$MyInvocation.MyCommand.Name.IndexOf("."))
$LOGF    = "${AplPath}\log\${SHID}.log"

.${AplPath}\bin\KTSK_ENV.ps1
.${AplPath}\bin\function.ps1

$driver = Create-EdgeDriver

$driver.Navigate().GoToURL("https://rsv.shisetsu.city.katsushika.lg.jp/katsushika/web/index.jsp")

$driver.ExecuteScript("javaScript:canLogin()")

$driver.ExecuteScript("javascript:doPpsdSearchAction((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchPpsdAction)")

$driver.ExecuteScript("javascript:sendPpsdCd((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchPpsAction, '200','2')")

$driver.ExecuteScript("javascript:doTransInstSrchBuildAction((_dom == 3) ? document.layers['disp'].document.form1 : document.form1, gRsvWTransInstSrchBuildAction, '200' , '200600')")


$emptyCoats = New-Object 'System.Collections.Generic.List[PSObject]'

#１ヶ月以内の平日リスト
$weekdays = creatWeekdayList

#調べるコートのリスト
$CoatKeys = $COAT_URL_HASH2.Keys

try{

#///////////////空きコートの検索////////////////////
foreach ( $CoatKey in $CoatKeys ){
    $CoatKey
    
    $URL = $COAT_URL_HASH2[$CoatKey]

    $driver.ExecuteScript($URL)
    Start-Random-Sleep
    
    foreach ( $weekday in $weekdays ){
    
        "対象日付：" + ${weekday}.ToString("yyyy-MM-dd")
    
        $y = $weekday.ToString("yyyy")
        $m = $weekday.ToString("MM")
        $d = $weekday.ToString("dd")
        
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
            $imgTags = $TD_ELEMENTS.FindElements([By]::TagName("img")) #最終回(夜間)だけ検索
            for ($i=0; $i -lt $imgTags.Count; $i++){
            #$imgTags | %{

                if($imgTags[$i].GetAttribute("src").Contains("lw_emptybs.gif") -eq "True"){
                    #$emptyImgs = $emptyImgs + 1 

                    $TH_HEADERS = $TR_HEADER.FindElements([By]::TagName("TH"))
                    $TH_HEADERS = $TH_HEADERS[1..$TH_HEADERS.Count] #ヘッダの1列目はYYYY年MM月DD日）

                    $coat = createCoatObject $CoatKey $weekday $TH_HEADERS[$i] $TR
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

#///////////////空きコートの検索////////////////////

} catch [Exception] {
    $Error[0] >>$LOGF

}


#///////////////メール送信対象の選定////////////////////
$Notice_List = @()
$emptyCoats | %{

 if($_.TimeFrom.Contains("18")){ #18時以降
    $Notice_List += $_
 }

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
【平日空き状況】

※下記のコートが開いています↓↓
${BodyCoat}

■葛飾区公共施設予約システム
https://rsv.shisetsu.city.katsushika.lg.jp/web/menu.jsp
(10009312/1231)
"@

#$res = sendLine $BODY_TAMPLATE
<#
if(-not($res.status -eq "200")){
    throw
}
 #>

}

(Get-date -format g) + " 空きコート：" + $Notice_List.Count >>$LOGF

$driver.Quit()
$driver = $NULL

[GC]::Collect()

exit 0

trap {
      "★例外エラー：" + (Get-date -format g)                        #>> $LOGF
      $Error[0]                                                    #>> $LOGF
      
      #sendLine $Error[0]
      
      $driver.Quit()
      $driver = $NULL

      [GC]::Collect()
      
      exit 1
     }
