    $token = "wyaSjzKBGaOFb2yOe6k3U+nZtLHlpamVoYUW6COUOV+tbV0M2BtPgTQ/IQ8n7zAJx5cZi6KY8zgdyvTxbt/R4g+Mnvd6vFSFhBiFZ1bKcw7aHEa5Toczh0VdodTpShEiNaT+Tp/5oNWHDGypECx0sQdB04t89/1O/w1cDnyilFU="
    $userId = "Uc55ce228e248ee7ac0059affb7371745"

    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    $body = @{
        to = $userId
        messages = @(
            @{
                type = "text"
                text = "ほほい
                あｓだだ
                あｄさだあｄさだ"
            }
        )
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod `
        -Uri "https://api.line.me/v2/bot/message/push" `
        -Method Post `
        -Headers $headers `
        -Body $body
