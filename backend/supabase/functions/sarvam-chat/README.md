# Sarvam text chat function

This authenticated Edge Function proxies the Regular-navigation chatbot to
Sarvam Chat Completions without exposing the API subscription key in Flutter.

Deploy it from an account with Owner or Administrator access to the `MSS APP`
Supabase project:

```powershell
npx supabase secrets set --project-ref houpzsxmwemoztpuigmo SARVAM_API_KEY=YOUR_KEY
npx supabase functions deploy sarvam-chat --project-ref houpzsxmwemoztpuigmo
```

The function pins the conversational model and generation controls in server
code, bounds client-provided history, requires a valid Supabase session, and
does not send the user's saved profile or other hidden PII to Sarvam.
