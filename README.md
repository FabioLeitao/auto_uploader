# auto_uploader
Bash script para automação de transferência de arquivos

Busca pelo conteúno numa pasta predeterminada, ou passada como parâmetro, confere se mudou o conteúdo recentemente (para tentar previnir agir sob arquivos ainda incompletos), tenta transferir para um servidor via SFTP utilizando credenciais pre-configuradas.

Será necessário configurar um arquivo .ssh/config na pasta do usuário indicando o correto acesso ao servidor publicado semelhante ao descrito abaixo:

![image](https://github.com/FabioLeitao/auto_uploader/assets/1284395/26d8f445-5237-4cce-a248-b021ffe937e6)

O script vai guardar os arquivos em uma pasta de bkp e contar os sucessos em log separado.
