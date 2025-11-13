# 🗺️ Arauc Tech Challenge

Aplicação Flutter desenvolvida como parte do desafio técnico da Arauc Tecnologia.
O objetivo do projeto é permitir que o usuário desenhe áreas diretamente sobre um mapa (via Google Maps), salvando e recuperando esses desenhos de uma API REST.

## 🚀 Funcionalidades principais

- ✏️ Desenhar polígonos sobre o mapa
- 💾 Salvar e carregar desenhos a partir da API da Arauc
- 🗑️ Excluir desenhos existentes
- ⏳ Exibição de spinner durante carregamentos e requisições
- 🧭 Posicionamento interativo no mapa com Google Maps
- 🧱 Interface responsiva e simples de usar
- 🧹 Código estruturado e documentado

## 🧩 Estrutura do projeto
```bash
lib/
│
├── main.dart                         # Ponto de entrada do app
├── widgets/
│   ├── drawingMap.dart               # Widget responsável por mostrar o mapa, e permitir o desenho por cima dele
│   ├── mapPainter.dart               # Responsável por renderizar os traços desenhados sobre o mapa
│   ├── toolBox.dart                  # Widget do caixa de ferramentas, tag de "doenças" e "pragas" e do "brush" e da "borracha"
│   └── weekNavigator.dart            # Widget da navegação entre semanas
│
├── services/
│   ├── drawing_service.dart          # Gerencia carregamento e salvamento dos desenhos
│   ├── cloud_service.dart            # Comunicação com a API
│   └── converter.dart                # Converte polygons em JSON
│
├── models/
│   ├── strokeModel.dart              # Modelo de linha desenhada
│
└── controllers/
    ├── drawingController.dart        # Responsável por renderizar os strokes no canvas
```

## ⚙️ Tecnologias e dependências
| Dependência |	Versão | Descrição |
|-------------|--------|-----------|
| flutter |	3.x |	Framework principal |
| google_maps_flutter	| ^2.6.0 |	Exibe e manipula o mapa do Google| 
| http | ^1.1.0 |	Requisições à API| 
| flutter_dotenv | ^5.1.0 |	Carrega variáveis do .env| 
| xml |	^6.5.0 |	Manipulação e parsing de XML| 
| intl | ^0.18.1 |	Formatação de datas e horários| 
| font_awesome_icon_class | ^0.0.6 |	Ícones adicionais| 
| flutter_launcher_icons |	^0.14.4 |	Configuração do ícone do app| 
| cupertino_icons |	^1.0.8 |	Ícones padrão do Flutter |


## 🧠 Arquitetura e conceitos

### O app segue uma estrutura modular baseada em separação de responsabilidades:

- Models: Definem a estrutura dos dados (ex: Stroke).

- Services: Camada lógica que interage com APIs e gerencia estado.

- Controllers: Responsáveis pela renderização visual dos desenhos.

- Widgets: Elementos de interface com o usuário.

A comunicação com o backend é feita por meio de requisições HTTP utilizando http, com suporte a .env para armazenar variáveis de ambiente (como a URL da API).

## 🔄 Fluxo geral

- O usuário acessa a tela principal com o mapa.

- Pode desenhar áreas com o toque (gerando strokes).

- Ao salvar, o desenho é convertido em JSON e enviado à API.

- Ao abrir novamente, o app busca o desenho salvo e o redesenha.

- Também é possível excluir o desenho via requisição DELETE.

## 🧱 Extras implementados

- Spinner de carregamento durante operações assíncronas

- Botão de exclusão de desenho com diálogo de confirmação

- Ícone do app personalizado com a logo da Arauc

- Código totalmente documentado e legível

## 🧪 Como rodar o projeto
- 1️⃣ Clonar o repositório

```bash
git clone https://github.com/SEU_USUARIO/arauc-tech-challenge.git
cd arauc-tech-challenge
```
- 2️⃣ Configurar o .env
  
Crie um arquivo .env na raiz do projeto com a URL base da API:
```
BASEURL=https://exemplo.com/api/
USERNAME=example
SENHA=example123
```
- 3️⃣ Instalar dependências
```bash
flutter pub get
```
- 4️⃣ Executar o app
```bash
flutter run
```
- 🧱 Gerar APK
Para gerar o arquivo .apk de build:
```bash
flutter build apk --release
```

O arquivo será gerado em:
```bash
build/app/outputs/flutter-apk/app-release.apk
```
## 🧩 Licença

Projeto desenvolvido exclusivamente para o desafio técnico da Arauc Tecnologia.
Uso restrito para fins de avaliação.