$envPath = ".env"

$openai = Read-Host "Entrez votre OPENAI_API_KEY"
$supabaseUrl = Read-Host "Entrez l'URL de votre projet Supabase"
$supabaseKey = Read-Host "Entrez la clé secrète Supabase"
$elevenlabs = Read-Host "Entrez votre ELEVENLABS_API_KEY (laisser vide si inutilisé)"

$envContent = @"
OPENAI_API_KEY=$openai
MODEL=gpt-4o
LANG=fr
SUPABASE_URL=$supabaseUrl
SUPABASE_KEY=$supabaseKey
GOOGLE_APPLICATION_CREDENTIALS=auth/doublenumerique-yann.json
ELEVENLABS_API_KEY=$elevenlabs
"@
Set-Content -Path $envPath -Value $envContent -Encoding UTF8
Write-Host "✅ Fichier .env généré avec succès dans '$envPath'" -ForegroundColor Green
