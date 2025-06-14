# Éditto Magazine

O Éditto é um aplicativo Flutter que usa IA para gerar revistas digitais personalizadas baseadas em qualquer tema. O app oferece uma interface intuitiva para criar, gerenciar e ler publicações personalizadas.

## Funcionalidades

- **Criação de Revistas Personalizadas**: Gere revistas sobre qualquer tópico de interesse
- **Conteúdo Gerado por IA**: Cria automaticamente artigos e imagens de capa usando IA
- **Suporte Multilíngue**: Disponível em inglês e português do Brasil
- **Tema Claro/Escuro**: Interface adaptável com suporte ao tema do sistema
- **Biblioteca Digital**: Coleção pessoal de revistas geradas
- **Design Responsivo**: Funciona em plataformas móveis, tablets e desktop
- **Autenticação Segura**: Autenticação de usuário baseada em Firebase 
- **Armazenamento em Nuvem**: Todas as revistas são armazenadas com segurança no Firebase Storage
- **Compras no App**: Integração com Stripe para compra de moedas para criação de revistas

## Detalhes Técnicos

- Construído com Flutter e Dart
- Gerenciamento de estado usando Riverpod
- Backend Firebase (Auth, Firestore, Storage)
- Integração de pagamento com Stripe
- Geração e manipulação de PDF
- Princípios de design de UI responsivo
- Suporte à localização
- Personalização de tema

## Arquitetura

O app é estruturado com os seguintes componentes principais:

- `lib/pages/`: Telas principais do aplicativo
- `lib/utilities/`: Classes auxiliares e utilitários
- `lib/widgets/`: Componentes de UI reutilizáveis

## Funcionalidades Principais

### Criação de Revista
- Geração de conteúdo baseado em tema
- Acompanhamento de progresso
- Compilação de PDF
- Geração de imagem de capa

### Gerenciamento de Usuário
- Autenticação
- Preferências do usuário
- Biblioteca de revistas
- Histórico de compras

### Sistema de Pagamento
- Economia baseada em moedas
- Processamento seguro de pagamentos
- Múltiplas opções de pacotes
- Preços baseados na região (USD/BRL)

## Como Começar

1. Clone o repositório
2. Configure o ambiente de desenvolvimento Flutter
3. Configure o projeto Firebase
4. Adicione as chaves de pagamento do Stripe
5. Execute `flutter pub get`
6. Inicie o app com `flutter run`

## Configuração do Ambiente

Certifique-se de ter o seguinte configurado:

- SDK do Flutter
- Projeto Firebase com serviços necessários habilitados
- Conta Stripe para pagamentos
- Variáveis de ambiente de desenvolvimento

## Licença

Este projeto é um software proprietário. Todos os direitos reservados.

## Sobre

O Éditto Magazine é uma plataforma que permite aos usuários criar revistas digitais personalizadas usando tecnologia de IA. O aplicativo combina geração automatizada de conteúdo com layouts profissionais para entregar publicações de alta qualidade sobre qualquer tema.


