<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Apex - Réinitialisation de mot de passe</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0f172a; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #f8fafc;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0f172a; padding: 40px 16px;">
        <tr>
            <td align="center">
                <table role="presentation" width="100%" style="max-width: 520px; background-color: #1e293b; border-radius: 16px; border: 1px solid #334155; overflow: hidden; padding: 36px 28px;">
                    <tr>
                        <td align="center" style="padding-bottom: 24px;">
                            <span style="font-size: 26px; font-weight: 800; letter-spacing: 2px; color: #f97316;">APEX</span>
                        </td>
                    </tr>
                    <tr>
                        <td style="font-size: 18px; font-weight: 600; color: #f1f5f9; padding-bottom: 12px; text-align: center;">
                            Réinitialisation de votre mot de passe
                        </td>
                    </tr>
                    <tr>
                        <td style="font-size: 15px; line-height: 1.6; color: #94a3b8; padding-bottom: 24px; text-align: center;">
                            Une demande de réinitialisation de mot de passe a été initiée pour votre compte Apex. Entrez le code à 6 chiffres suivant dans l'application :
                        </td>
                    </tr>
                    <tr>
                        <td align="center" style="padding-bottom: 24px;">
                            <div style="display: inline-block; background-color: #0f172a; border: 1px solid #f97316; border-radius: 12px; padding: 16px 32px; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #f97316; font-family: monospace;">
                                {{ $code }}
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="font-size: 13px; line-height: 1.6; color: #64748b; text-align: center; padding-bottom: 8px;">
                            Ce code est valable pendant <strong>15 minutes</strong>. Tous vos accès en cours seront révoqués après la réinitialisation.
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
