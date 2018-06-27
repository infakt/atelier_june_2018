# Integracja aplikacji w Ruby on Rails z Google Calendar

## Nasz dzisiejszy cel

Chcemy połączyć aplikację Atelier z Google
Calendar w taki sposób, aby:
- wypożyczenie książki (akcja `#take`) tworzyło event w kalendarzu
- oddanie książki (akcja `#return`) usuwało event z kalendarza

Nasz użytkownik będzie przy rejestracji via Google Oauth pytany o zgodę
na udostępnienie swoich kalendarzy Google. Przed skorzystaniem z
funkcjonalności, będzie musiał sobie ręcznie utworzyć kalendarz o nazwie 'atelier'

## Jak to zrobimy?

Będziemy zarządzać kalendarzem użytkownika przy użyciu API Google
Calendar. Do autoryzacji wykorzystamy zrobioną już wcześniej integrację
z Google Omniauth 2, a samą komunikację z API kalendarza zapewni nam
nowy gem, który zaraz zainstalujemy w naszym projekcie. Następnie
stworzymy nowy serwis, w którym użyjemy interfejsu dostarczonego przez gem.
Serwis ten będzie odpowiedzialny za:
- wysyłkę eventu do kalendarza użytkownika (wraz z podstawowymi informacjami o
  książce) + zapis numeru id eventu z kalendarza Google
- usuwanie eventu z kalendarza (na podstawie statusu rezerwacji i numeru
  eventu)

Serwis wywoływany będzie w miejscu, które odpowiada za wypożyczenie / oddanie książki. 
Rozważać będziemy tutaj przypadek bazowy (czyli ten przed refactoringiem z pierwszego
spotkania) gdzie akcje odpowiedzialne za zmianę statusów rezerwacji trzymaliśmy w 
modelu `Book`.

## Dwie ważne rzeczy, zanim zaczniesz!

1. Każdy użytkownik naszej aplikacji musi sobie przed przystąpnieniem do
   rejestracji przy użyciu GMaila ręcznie dodać nowy kalendarz Google o
   nazwie 'atelier'.
2. Użytkownicy naszej aplikacji muszą mieć unikalne adresy e-mail.
   Z tego powodu nie uda nam się rejestracja via Google OmniAuth, jeśli
   wcześniej zarejestrowaliśmy konto w Atelier na ten sam e-mail (podając
   go 'z palca' w formularzu rejestracyjnym). Proponowana
[tutaj](https://github.com/infakt/atelier_june_2018/pull/12/files#diff-4676c008b11a5480d73d4a6de01e45b9R12)
   implementacja metody autoryzującej opierała się na założeniu
   (podjętym na potrzeby uproszczenia tutorialu), że w takim wypadku
   zalogujemy użytkownika na istniejące już konto. Rozwiązanie to ma
   jednak pewną wadę: ponieważ nie wymagamy potwierdzenia adresu e-mail,
   rejestrując się poprzez formularz możemy łatwo stworzyć konto
   podszywające się pod istniejący adres, lub też możemy się po prostu
   pomylić w adresie i ktoś, kto posługuje się wpisanym przez nas
   e-mailem może nam to konto przejąć, rejestrując się poprzez OmniAuth.
   Zdecydowaliśmy się więc na proste rozwiązanie, które wiąże się z
   identyfikowaniem użytkowników poprzez 'uid' nadawane przez Google.
   Jeśli nie ma w naszej bazie usera z danym uid, tworzymy nowe konto.
   Jeśli w dalszym kroku okaże się, że mamy zdublowany adres e-mail,
   zadziała nam blokada dzięki walidacji na modelu i konto nie zostanie
   w Atelier utworzone, a użytkownikowi pokaże się też komunikat z walidacji
   mówiący o tym, że adres jest już zajęty. Z kolei jeśli w naszej bazie
   już jest user z danym uid, zostanie on zalogowany do Atelier.

   TLDR: Jeśli masz w swojej bazie problematycznego użytkownika
   (skrzynka na GMailu wpisana 'z palca' przy rejestracji),
   najlepiej będzie go usunąć i zarejestrować ponownie via Google ;)

## Do dzieła!

### 1. Konfiguracja

Aby zabezpieczyć nasze dane dostępowe, instalujemy gem `A9n` - jeśli jeszcze go
nie mamy w projekcie - i tworzymy plik `config/configuration.yml.example`.
Dodajemy do pliku `.gitignore` linijkę:
    ```
    configuration.yml
    ```

następnie uzupełniamy pliki `configuration.yml` i `configuration.yml.example`:
   ```
   defaults:
     google_client_id: '__twoje_client_id__'
     google_client_secret: '__twoj_client_secret__'
     default_calendar: { summary: 'atelier' }
     app_host: 'http://localhost:3000'

   ```

  W `configuration.yml` powinniśmy oczywiście wpisać prawdziwe wartości
naszych kluczy `google_client_id` oraz `google_client_secret`, które
przekopiujemy sobie ze swojego [panelu deweloperskiego Google](https://console.developers.google.com)
Co do reszty kluczy, `default_calendar` przyda nam się później do budowy zapytań do API, a
`app_host` pomoże nam zbudować poprawnie działający link do podstrony
naszej książki (link ten będziemy umieszczać w opisie eventu w
kalendarzu użytkownika).

  Ważną rzeczą jest konfiguracja omniauth w taki sposób, aby użytkownik
mógł udostępnić nam swoje kalendarze Google. Dokonamy tego, uzupełniając
pusty do tej pory hash następującymi wartościami:

```ruby
# plik: config/initializers/devise.rb

  config.omniauth :google_oauth2, A9n.google_client_id, A9n.google_client_secret, {
    access_type: "offline",
    prompt: "consent",
    select_account: true,
    scope: 'userinfo.email, calendar'
  }

```

### 2. Dodajemy gem `google-api-client`

  Będziemy posługiwać się następującym gemem: [https://github.com/google/google-api-ruby-client](https://github.com/google/google-api-ruby-client)

  Dla zapewnienia stabilności działania z Rails 5, użyjemy wersji `0.8.2`. Dodajmy do pliku Gemfile:
```
gem 'google-api-client', '0.8.2', require: 'google/api_client'
```

oraz zainstalujmy nasz gem:
```
$ bundle
```

Efektem będą zmiany w `Gemfile` i `Gemfile.lock`.

WAŻNE: wersja 0.8.2 najlepiej współpracuje z ruby 2.4.1 i właśnie taką
należy określić w pliku ./.ruby-version oraz mieć zainstalowaną ;)

### 3. Włączamy w konsoli Google dostęp do API kalendarza.

Tę operację wykonamy jednorazowo. Analogicznie [jak w poprzednim
tutorialu](https://github.com/infakt/atelier/wiki/Tutorial:-OAuth-2#setup-google-api)

Wchodzimy w [link](https://console.developers.google.com/apis/) i
klikamy `[enable apis and services]`, wyszukujemy 'google calendar api',
klikamy w wynik, a następnie w `[enable]`.

### 4. Nowe kolumny w tabeli `users`.

Mamy dostęp do nowego API i narzędzie do komunikacji z nim (gem
google-api-client). Na potrzeby korzystania z API Google Calendar
będziemy przechowywać w bazie danych token użytkownika (oraz
refresh_token, który posłuży nam do odświeżania przedawnionego tokena).
Przyda nam się też `provider` oraz `uid` do jednoznacznej identyfikacji
konta użytkownika. Przygotujmy więc odpowiednią migrację:

```
$ rails g migration add_oauth_fields_to_users
```

i w pliku z migracją wpiszmy:
```ruby
class AddOauthFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :token, :string
    add_column :users, :refresh_token, :string
  end
end
```
a następnie:
```
$ rake db:migrate
```

### 5. Dostosowanie serwisu `UserFromOmniauthGetter`

Zakładamy, że mamy już ogarnięte logowanie via Omniauth, tak jak w [tym commicie](https://github.com/infakt/atelier/pull/33/files#diff-412d4164e2fc9a90797b079f264bfeb9R1).
Opierając się na tym kodzie, popracujmy nad przypisaniem użytkownikowi brakujących informacji, czyli
`token`, `refresh_token`, `uid` i `provider`. Osiągniemy to w
następujący sposób:

```ruby
# plik: app/services/user_from_omniauth_getter.rb
class UserFromOmniauthGetter
  def initialize(access_token)
    @access_token = access_token
  end

  def perform
    User.where(provider: access_token.provider, uid:
      access_token.uid).first_or_create do |user|
      user.provider = access_token.provider
      user.uid = access_token.uid
      user.email = access_token.info.email
      user.password = Devise.friendly_token[0,20]
      user.token = access_token.credentials.token
      user.refresh_token = access_token.credentials.refresh_token
      user.save
    end
  end

  private

  attr_reader :access_token
end

```
### 6. Dodanie kolumny `calendar_event_oid` w tabeli `book_reservations`

Ponieważ oprócz dodawania eventów do kalendarza chcemy też móc je
usuwać, musimy gdzieś przechowywać ich unikalne numery id. Wykorzystamy
do tego celu nową kolumnę w tabeli `book_reservations`. Migracja powinna
wyglądać tak:

```
$ rails g migration add_calendar_event_oid_to_reservations
```

i potem w nowopowstałym pliku:

```ruby
class AddCalendarEventOidToReservations < ActiveRecord::Migration[5.1]
  def change
    add_column :book_reservations, :calendar_event_oid, :string
  end
end

```

nie zapominamy o:

```
$ rake db:migrate
```

### 7. Stworzenie nowego serwisu do zarządzania eventami kalendarza.

Teraz stworzymy klasę, która odpowiedzialna będzie za wysyłkę eventów
do kalendarza (oraz ich usuwanie w razie konieczności). Ponieważ chcemy,
aby był to serwis, umieścimy nowy plik w  w `app/services/`. Nazwijmy
nasz plik `user_calendar_notifier.rb`.

Przejdziemy razem przez cały proces tworzenia naszej klasy :)

Będzie to klasyczny serwis z tylko jedną metodą publiczną `#perform`
i szeregiem metod prywatnych. Ponieważ serwis nasz będzie odpowiedzialny
za zarządzanie kalendarzem użytkownika, w ramach inicjalizacji przekażmy
obiekt klasy `User`, aby móc odpowiednio skonfigurować połączenie. W
metodzie `#perform` będziemy przekazywać obiekt `Reservation`, ponieważ
nasz event w kalendarzu będzie z nim ściśle powiązany.

```ruby
class UserCalendarNotifier
  def initialize(user)
  end

  def perform(reservation)
  end
end
```

W metodzie `initialize` zamieścimy teraz kod, którego zadaniem będzie
przypisanie zmiennych instancji naszej klasy.

Zmienna `@client`będzie nowym obiektem klasy `Google::APIClient`. Klasa
ta jest zdefiniowana w gemie i jest prawdziwym bossem ;) bo zawiera
bardzo ważną metodę `execute`, którą posługiwać się będziemy później,
aby 'pukać' do odpowiedniego API.

Zmienna @service będzie obiektem klasy `Google::APIClient::API`.
Otrzymamy ten obiekt, wywołując na obiekcie `@client` metodę
`#discovered_api`, podając w jej parametrach typ i wersję interesującego
nas API.

Zanim jednak użyjemy metody `#discovered_api` musimy skonfigurować nasz
obiekt `@client`, ustawiając w nim wszystkie potrzebne dane autoryzujące,
oraz odświeżyć token użytkownika na wypadek, gdyby wygasł (to się może
zdarzyć, gdy użytkownik nie przelogowywał się przez dłuższy czas).

Gotowe ciało naszej metody wyglądać więc będzie następująco:


```ruby
  def initialize(user)
    @client = Google::APIClient.new
    client.authorization.access_token = user.token
    client.authorization.refresh_token = user.refresh_token
    client.authorization.client_id = A9n.google_client_id
    client.authorization.client_secret = A9n.google_client_secret
    client.authorization.refresh!
    @service = client.discovered_api('calendar', 'v3')
  end
```
aby móc odwoływać się w wygodny sposób do zmiennej instancji `@client`,
tworzymy akcesory:

```ruby
private
attr_accessor :client, :service
```

Skoro mamy już nasz 'konstruktor' obiektu `UserCalendarNotifier`, nadchodzi
czas na najważniejszą metodę `#perform`. Poczytaliśmy dokumentację i wiemy, że
jeśli chcemy tworzyć eventy w kalendarzu, musimy znać jego ID. Podobnie
w przypadku usuwaniu eventów - musimy znać również ich ID. Załóżmy więc, że
zadaniem metody `#perform` będzie:

1. Odnaleźć poprzez API kalendarz o kryteriach {'summary' => 'atelier'}
2. Pozyskać unikalny numer ID tego kalendarza (będzie zaszyty gdzieś w
   odpowiedzi z API)
3. Wykonać ponowne zapytanie do API, tym razem tworzące event w
   kalendarzu (lub usuwające go).
4. W przypadku, gdy tworzymy nowy event, zapisać jego unikalny numer ID
   w naszej bazie danych, wiążąc go z konkretną rezerwacją. Będzie on
   konieczny przy akcji usuwania eventu.

Nasza metoda będzie mieć więc do wykonania kilka zadań. Intuicja mówi,
że najlepiej by było te zadania gdzieś oddelegować. Idealnie do tego
celu nadadzą się metody prywatne naszej klasy.

ad 1. metoda prywatna `#find_calendar`

Nasza metoda będzie mieć za zadanie znaleźć konkretny kalendarz
użytkownika. Podamy jej odpowiednie krytera jako parametr (w formie
hasha). Może ona na początek wyglądać tak:

```ruby
def find_calendar
  json_response = client.execute(api_method: service.calendar_list.list)
  hash = JSON.parse(json_response.body)
  items = hash['items']
  items.find {|entry| entry['summary'] == 'atelier'}
end
```

Widzimy, że sporo się tu dzieje:
* Najpierw robimy zapytanie do API przy użyciu `client.execute`, jako
metodę api podając `service.calendar_list.list`, czyli listę kalendarzy
* Parsujemy odpowiedź (pobieramy jej 'body' i zamieniamy z formatu JSON na hash)
* Z hasha wyciągamy tablicę będącą listą kalendarzy (znajduje się ona pod kluczem 'items')
* wyszukujemy w tablicy interesujący nas element przy użyciu `#find`

Można zatem rozbić naszą metodę na kilka mniejszych, np. w ten sposób:

```ruby
def find_calendar
  calendar_list.find {|entry| entry['summary'] == 'atelier'}
end

def calendar_list
  response_body_hash(
    client.execute(api_method: service.calendar_list.list)
  )['items']
end

def response_body_hash(response)
  JSON.parse(response.body)
end
```

Świetnie, ale jest jeden szczegół, który warto poprawić. Wpisaliśmy na
sztywno kryterium wg którego szukamy kalendarza ('summary' =>
'atelier'). Lepiej by było trzymać taką rzecz w konfiguracji aplikacji.
Użyjmy więc parametru :)

```ruby
def find_calendar_by(hash)
  calendar_list.find { |entry| entry[hash.keys.first.to_s] == hash.values.first }
end
```

Od tej pory jako hash przekazywać będziemy `A9n.default_calendar`.

ad 2. pozyskanie numeru ID kalendarza

Sprawa jest prosta. Ponieważ nasz kalendarz jest tak naprawdę hashem,
możemy odczytać jego id w następujący sposób:

```ruby
find_calendar_by(A9n.default_calendar)['id']
```

Wykorzystamy ten szczegół w następnym punkcie.

ad 3. zapytanie do API poprzez wykonanie `client.execute`

Mamy id kalendarza, mamy klienta API, możemy wysłać zapytanie przy
użyciu gemu. W dokumentacji znajdziemy informację na temat tego,
co i jak musimy przekazać w parametrach, gdy chcemy utworzyć nowy event.

Nasza metoda `#perform` może na początek wyglądać tak:

```ruby
def perform(reservation)
  client.execute(
    {
      api_method: service.events.insert,
      parameters: {
        'calendarId' => find_calendar_by(A9n.default_calendar)['id'],
        'sendNotifications' => true,
        },
      body: JSON.dump(
        {
          summary: "'#{reservation.book.title}' expires",
          location: 'Library',
          start: {
            dateTime: reservation.expires_at.utc.strftime("%Y-%m-%dT%H:%M:%S%z")
          },
          end: {
            dateTime: reservation.expires_at.utc.strftime("%Y-%m-%dT%H:%M:%S%z")
          },
          description: "Book '#{reservation.book.title}' (ISBN: #{reservation.book.isbn})<br><a href='#{A9n.app_host}/books/#{reservation.book.id}'>link to book page</a>"
        }
      ),
      headers: {'Content-Type' => 'application/json'}
    }
  )
end
```

Warto rozbić to na mniejsze metody. Po refactoringu będzie tak:

```ruby
def perform(reservation)
  client.execute(
    api_params(
      find_calendar_by(A9n.default_calendar)['id'],
      reservation
    )
  )
end

private

def api_params(cal, reservation)
  {
    api_method: service.events.insert,
    parameters: {
    'calendarId' => cal['id'],
    'sendNotifications' => true,
  },
    body: JSON.dump(event(reservation)),
    headers: {'Content-Type' => 'application/json'}
  }
end

def event(reservation)
  {
    summary: "'#{reservation.book.title}' expires",
    location: 'Library',
    start: { dateTime: format_time(reservation.expires_at) },
    end:   { dateTime: format_time(reservation.expires_at) },
    description: "Book '#{reservation.book.title}' (ISBN: #{reservation.book.isbn})<br><a href='#{A9n.app_host}/books/#{reservation.book.id}'>link to book page</a>"
  }
end

def format_time(time)
  time.utc.strftime("%Y-%m-%dT%H:%M:%S%z")
end
```

Wszystko świetnie, ale... co, jeśli nie odnajdziemy kalendarza u
użytkownika? Rozsądek podpowiada, że powinniśmy go najpierw poszukać, a
dopiero gdy znajdziemy, wykonywać na nim jakieś operacje. Zmienimy więc
kolejność wywołań w następujący sposób:

```ruby
def perform(reservation)
  calendar = find_calendar_by(A9n.default_calendar)
  client.execute(api_params(calendar, reservation)) unless calendar.nil?
end
```

Nie musimy przypisywać kalendarza do zmiennej, możemy użyć `#tap`:

```ruby
def perform(reservation)
  find_calendar_by(A9n.default_calendar).tap {|cal|
    client.execute(api_params(cal, reservation)) unless cal.nil?
  }
end
```

ad 4. zapisanie ID naszego eventu

Nie możemy zapomnieć o bardzo ważnej rzeczy, czyli zapisaniu ID eventu,
który właśnie nam się utworzył. Przyda się on później, gdy będziemy
chcieli skasować event z kalendarza. I tutaj bardzo przyda nam się
utworzona wcześniej metoda `#response_body_hash`:

```ruby
def perform(reservation)
  find_calendar_by(A9n.default_calendar).tap {|cal|
    unless cal.nil?
      response = client.execute(api_params(cal, reservation))

      if reservation.taken?
        reservation.update_attributes(
          calendar_event_oid: response_body_hash(response)['id']
        )
      end
    end
  }
end
```

Wszystko już PRAWIE gotowe... pozostał nam jeszcze do obsłużenia
przypadek, gdy książka jest zwracana do biblioteki i chcemy usunąć event
z kalendarza. Ponieważ usuwanie książki to tak naprawdę użycie kolejnej
metody API (z nieco innymi parametrami), rozbudujemy nieco metodę
`#api_params`, która zwraca nam parametry zapytań do API Google:

```ruby
def api_params(cal, reservation)
  if reservation.taken?
    {
      api_method: service.events.insert,
      parameters: {
      'calendarId' => cal['id'],
      'sendNotifications' => true,
    },
      body: JSON.dump(event(reservation)),
      headers: {'Content-Type' => 'application/json'}
    }
  elsif reservation.status == 'RETURNED' && reservation.calendar_event_oid.present?
    {
      api_method: service.events.delete,
      parameters: {
        'calendarId' => cal['id'],
        'eventId' => reservation.calendar_event_oid
      }
    }
  end
end
```

I to w zasadzie tyle :) Poniżej gotowy kod naszej klasy, w pełnej okazałości:

```ruby
class UserCalendarNotifier
  def initialize(user)
    @client = Google::APIClient.new
    client.authorization.access_token = user.token
    client.authorization.refresh_token = user.refresh_token
    client.authorization.client_id = A9n.google_client_id
    client.authorization.client_secret = A9n.google_client_secret
    client.authorization.refresh!
    @service = client.discovered_api('calendar', 'v3')
  end

  def perform(reservation)
    find_calendar_by(A9n.default_calendar).tap {|cal|
      unless cal.nil?
        response = client.execute(api_params(cal, reservation))

        if reservation.taken?
          reservation.update_attributes(
            calendar_event_oid: response_body_hash(response)['id']
          )
        end
      end
    }
  end

  private
  attr_accessor :client, :service

  def api_params(cal, reservation)
    if reservation.taken?
      {
        api_method: service.events.insert,
        parameters: {
        'calendarId' => cal['id'],
        'sendNotifications' => true,
      },
        body: JSON.dump(event(reservation)),
        headers: {'Content-Type' => 'application/json'}
      }
    elsif reservation.status == 'RETURNED' && reservation.calendar_event_oid.present?
      {
        api_method: service.events.delete,
        parameters: {
          'calendarId' => cal['id'],
          'eventId' => reservation.calendar_event_oid
        }
      }
    end
  end

  def find_calendar_by(hash)
    calendar_list.find { |entry| entry[hash.keys.first.to_s] == hash.values.first }
  end

  def calendar_list
    response_body_hash(
      client.execute(api_method: service.calendar_list.list)
    )['items']
  end

  def response_body_hash(response)
    JSON.parse(response.body)
  end

  def event(reservation)
    {
      summary: "'#{reservation.book.title}' expires",
      location: 'Library',
      start: { dateTime: format_time(reservation.expires_at) },
      end:   { dateTime: format_time(reservation.expires_at) },
      description: "Book '#{reservation.book.title}' (ISBN: #{reservation.book.isbn})<br><a href='#{A9n.app_host}/books/#{reservation.book.id}'>link to book page</a>"
    }
  end

  def format_time(time)
    time.utc.strftime("%Y-%m-%dT%H:%M:%S%z")
  end

  private
end
```

### 8. Podpięcie serwisu pod akcje.

Wspaniale, mamy już nasz serwis. Czas na podpięcie go w odpowiednie miejsca w
aplikacji. Jak już napisano wcześniej, rozważymy przypadek, gdy do
obsługi rezerwacji mamy metody bezpośrednio w modelu `Book`.

W tym celu stworzymy w naszym modelu metodę prywatną:

```ruby
  private

  def notify_user_calendar(reservation)
    UserCalendarNotifier.new(reservation.user).perform(reservation)
  end
```

A następnie zadbamy o odpowiednie przekazanie obiektu rezerwacji:

```ruby
  def take(user)
    return unless can_take?(user)

    if available_reservation.present?
      available_reservation.update_attributes(status: 'TAKEN')
    else
      reservations.create(user: user, status: 'TAKEN')
    end.tap {|reservation|
      notify_user_calendar(reservation)
    }
  end

  def give_back
    ActiveRecord::Base.transaction do
      reservations.find_by(status: 'TAKEN').tap { |reservation|
        reservation.update_attributes(status: 'RETURNED')
        notify_user_calendar(reservation)
      }
      next_in_queue.update_attributes(status: 'AVAILABLE') if next_in_queue.present?
    end
  end
```

Jeśli nie mamy już metod `#take` i `give_back` w modelu, bo przenieśliśmy je
do serwisu, nie powinno nastręczać trudności dokonanie analogicznych zmian w
klasie serwisu, gdyż logika pozostanie niezmieniona.

### 9. Gotowe!

Od tej pory, gdy użytkownik kliknie w guzik odpowiedzialny za rezerwację
/ oddanie książki, w jego kalendarzu Google zostanie utworzony /
usunięty odpowiedni event.

### 10. Co dalej? (czyli: zadanie dodatkowe)

- Zauważ, że komunikacja z API zachodzi w naszym przypadku synchronicznie.
  Użytkownik musi po kliknięciu chwilę poczekać. Aby to poprawić, przenieś
  odpowiedni kod do workera, niech obsługa eventów w kalendarzu odbywa
  się w tle :) (przewidywany czas realizacji: ~30min)

- W celu uproszczenia tutoriala w naszej implementacji nie uwzględniamy
  przypadku użytkownika bez integracji z Google Oauth2. Trzeba to poprawić :)
  Dopisz kod, który spowoduje, że nie będziemy próbować łączyć się z kalendarzem,
  jeśli użytkownik nie ma tej integracji. (przewidywany czas realizacji: ~15min)
