# auto_uploader
Bash script para automação de transferência de arquivos

Busca pelo conteúno numa pasta predeterminada, ou passada como parâmetro, confere se mudou o conteúdo recentemente (para tentar previnir agir sob arquivos ainda incompletos), tenta transferir para um servidor via SFTP utilizando credenciais pre-configuradas.

Será necessário configurar um arquivo .ssh/config na pasta do usuário indicando o correto acesso ao servidor publicado:

O script vai guardar os arquivos e contar os sucessos
