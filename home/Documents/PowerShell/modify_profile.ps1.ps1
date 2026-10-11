{{- /* chezmoi:modify-template */ -}}
{{- $line := `. (Join-Path $HOME '.config/powershell/Dotfiles.ps1')` -}}
{{- if contains $line .chezmoi.stdin -}}
{{ .chezmoi.stdin }}
{{- else -}}
{{ .chezmoi.stdin }}
# Shared interactive settings. Existing profile commands remain above.
if ($PSVersionTable.PSVersion.Major -ge 7) {
    {{ $line }}
}
{{- end -}}
