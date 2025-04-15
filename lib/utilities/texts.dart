// Intro page texts in Portuguese
// Textos da página de introdução em português
List<String> introPT = [
  'Éditto', //0
  'Verdadeiramente Sua Magazine', //1
  'Começar', //2
];

// Intro page texts in English
// Textos da página de introdução em inglês
List<String> introEN = [
  'Éditto', //0
  'Truly Yours Magazine', //1
  'Get Started', //2
];

// Login page texts in Portuguese
// Textos da página de login em português
List<String> loginPT = [
  'Nome', //0
  'Email', //1
  'Senha', //2
  'Entrar', //3
  'Cadastrar', //4
  'Preencha todos os campos.', //5
  'A senha deve ter pelo menos 6 caracteres.', //6
  'Email inválido.', //7
  'Algo deu errado. Tente novamente mais tarde.', //8
  'O formato do endereço de email é inválido.', //9
  'Email ou senha incorreta.', //10
  'O email fornecido já está sendo utilizado por uma conta.', //11
  'Esqueceu sua senha?', //12
  'Um email foi enviado com o link para criar uma nova senha.', //13
  'Cancelar', //14
  'Enviar', //15
  'Login/Cadastro', //16
];

// Login page texts in English
// Textos da página de login em inglês
List<String> loginEN = [
  'Name', //0
  'Email', //1
  'Password', //2
  'Log In', //3
  'Sign Up', //4
  'Fill in all fields.', //5
  'The password must be at least 6 characters long.', //6
  'Invalid Email.', //7
  'Something went wrong. Please try again later.', //8
  'The email address is badly formatted.', //9
  'Wrong email or password.', //10
  'The provided email is already in use by an account.', //11
  'Forgot your password?', //12
  'An email has been sent with the link to create a new password.', //13
  'Cancel', //14
  'Send', //15
  'Login/Signup', //16
];

// Newsstand page texts in Portuguese
// Textos da página de banca em português
List<String> newsstandPT = [
  'Banca de Revistas', //0
  'Digite o tema', //1
  'ex: Tecnologia, Esportes, Política', //2
  'Hoje', //3
  'Última Semana', //4
  'Último Mês', //5
  'Comprar por', //6
  'Informe um tema, defina um período e deixe-nos cuidar do resto.', //7
  'Informe um tema de pelo menos 2 letras', //8
];

// Newsstand page texts in English
// Textos da página de banca em inglês
List<String> newsstandEN = [
  'Newsstand', //0
  'Enter theme', //1
  'e.g., Technology, Sports, Politics', //2
  'Today', //3
  'Last Week', //4
  'Last Month', //5
  'Buy for', //6
  'Enter a theme, set a time period and let us take care of the rest.', //7
  'Enter a theme with at least 2 letters', //8
];

// Rack page texts in Portuguese
// Textos da página de estante em português
List<String> rackPT = [
  'Minha Estante', //0
  'Erro ao carregar suas revistas.', //1
  'Você ainda não tem revistas.', //2
  'Imagem', //3
  'Capa', //4
  'Exibir como', //5
];

// Rack page texts in English
// Textos da página de estante em inglês
List<String> rackEN = [
  'My Rack', //0
  'Error loading your magazines.', //1
  'You don\'t have any magazines yet.', //2
  'Image', //3
  'Cover', //4
  'Display as', //5
];

// Map of all Portuguese texts
// Mapa de todos os textos em português
Map<String, List<String>> portugueseTexts = {
  'intro': introPT,
  'login': loginPT,
  'newsstand': newsstandPT,
  'rack': rackPT,
};

// Map of all English texts
// Mapa de todos os textos em inglês
Map<String, List<String>> englishTexts = {
  'intro': introEN,
  'login': loginEN,
  'newsstand': newsstandEN,
  'rack': rackEN,
};
