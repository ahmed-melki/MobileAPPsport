<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Apex - Code de vérification</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0f172a; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #f8fafc;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0f172a; padding: 40px 16px;">
        <tr>
            <td align="center">
                <table role="presentation" width="100%" style="max-width: 520px; background-color: #1e293b; border-radius: 16px; border: 1px solid #334155; overflow: hidden; padding: 36px 28px;">
                    <tr>
                        <td align="center" style="padding-bottom: 24px;">
                            <span style="font-size: 26px; font-weight: 800; letter-spacing: 2px; color: #38bdf8;">APEX</span>
                        </td>
                    </tr>
                    <tr>
                        <td style="font-size: 18px; font-weight: 600; color: #f1f5f9; padding-bottom: 12px; text-align: center;">
                            Validation de votre adresse email
                        </td>
                    </tr>
                    <tr>
                        <td style="font-size: 15px; line-height: 1.6; color: #94a3b8; padding-bottom: 24px; text-align: center;">
                            Bienvenue sur Apex. Pour finaliser la création de votre compte, saisissez le code de vérification suivant dans l’application mobile :
                        </td>
                    </tr>
                    <tr>
                        <td align="center" style="padding-bottom: 24px;">
                            <div style="display: inline-block; background-color: #0f172a; border: 1px solid #38bdf8; border-radius: 12px; padding: 16px 32px; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #38bdf8; font-family: monospace;">
                                {{ $code }}
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="font-size: 13px; line-height: 1.6; color: #64748b; text-align: center; padding-bottom: 8px;">
                            Ce code est valable pendant <strong>15 minutes</strong> et ne peut être utilisé qu'une seule fois.
                        </td>
                    </tr>
                    <tr>
                        <td style="font-size: 12px; line-height: 1.5; color: #475569; text-align: center;">
                            Si vous n'êtes pas à l'origine de cette demande, vous pouvez ignorer cet email en toute sécurité.
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
