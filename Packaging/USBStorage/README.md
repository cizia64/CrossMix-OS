# Correção de saída do USB Storage

O aplicativo gráfico USB Storage é fornecido pelo firmware do TrimUI. O processo auxiliar `usb_exit_watchdog` observa o botão B físico em `/dev/input/event3` (código Linux 304), aguarda sua soltura e encerra somente a interface da sessão atual quando recebe uma nova pressão. O launcher existente sincroniza, desativa o gadget USB e reinicia o aparelho. A tela original pede que a unidade seja ejetada no computador antes de pressionar B.

O monitor é copiado para `/tmp` antes da desmontagem do cartão. Se SD ou UDISK continuarem montados após a tentativa de desmontagem, o launcher cancela a exportação e reinicia. O console não consegue garantir que o computador tenha concluído suas gravações; a ejeção segura no computador continua necessária.

## Compilação e pacote

Na raiz do repositório, execute `bash System/resources/usb_storage/build_watchdog.sh` com Docker e a imagem `trimui-bigpicture:dev`. Depois execute `python Packaging/USBStorage/package.py <caminho-do-zip>`. Extraia o ZIP na raiz do cartão e abra Apps > Instalar correcao USB. O instalador verifica as cópias e guarda os arquivos substituídos em `Data/USBStorageFix`.

O mapeamento do botão vem dos scripts do CrossMix. O monitor foi verificado com entrada simulada, mas sua resposta ao botão físico e o retorno do USB Storage precisam ser confirmados no TrimUI Smart Pro. O log do monitor fica em `/tmp/usb_exit_watchdog.log` durante a sessão USB.
