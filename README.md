# Animais! — App para Bebês

Aplicação fullscreen onde o bebê pode pressionar **qualquer tecla** (ou tocar na tela) e ouvir um som de animal.

## Como usar

1. Dê duplo clique em `abrir.bat`
2. Clique ou pressione qualquer tecla para entrar em tela cheia
3. Cada toque/tecla toca **um único som** — teclas pressionadas juntas são ignoradas (debounce de 150 ms)

## Controles

- **Qualquer tecla** ou **toque na tela** → som de animal aleatório
- **ESC** → fechar o jogo e desligar a trava de teclado

## Sons

Os sons são gravações reais de animais (Mixkit, licença gratuita), salvos na pasta `sounds/`.

## Dica

O `abrir.bat` abre o jogo com `kiosk-lock.ps1`, que:

- Abre Microsoft Edge ou Google Chrome em modo quiosque
- Bloqueia atalhos como tecla Windows, `Alt+Tab`, `Alt+F4`, `Alt+Espaço`, `Ctrl+W`, `Ctrl+R`, `F1` a `F24` e teclas multimídia
- Fecha tudo quando `ESC` é pressionado

Para travar ainda melhor no Windows, use uma conta separada:

1. Crie um usuário local chamado, por exemplo, `Crianca`
2. Entre em **Configurações > Contas > Outros usuários > Configurar quiosque**
3. Escolha Microsoft Edge como aplicativo do quiosque
4. Use o endereço do arquivo `index.html` ou uma URL local para abrir o jogo
5. Deixe a conta principal com senha e use a conta `Crianca` só para o jogo

O bloqueador segura atalhos comuns, mas `Ctrl+Alt+Del` não pode ser bloqueado por programa comum por segurança do Windows.

Comando manual para abrir em quiosque no Edge:

```
msedge --kiosk "file:///caminho/completo/index.html" --edge-kiosk-type=fullscreen
```
