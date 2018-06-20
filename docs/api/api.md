# Dodanie funkcjonalności autocomplete przy użyciu API

Celem, który chcemy osiągnąć będzie wyszukiwarka książek! :) Użytkownik
będzie mieć do dyspozycji kilka pól, w których będzie mógł wpisać
interesujące go wartości (tytuł, isbn, kategoria). Autouzupełnianie
pomoże mu w tym, a gdy wybierze jedną z dostępnych wartości będzie mógł
sobie kliknąć w guzik, który odświeży listę książek bez przeładowania
strony. Brzmi poważnie? Nic strasznego ;)

### Co tu się za chwilę stanie...?

Użyjemy kilku rzeczy:
- wtyczki EasyAutocomplete [link do oficjalnej
  strony](http://easyautocomplete.com/)
- własnoręcznie stworzonego punktu API w naszej aplikacji, który
  generował będzie listę wszystkich książek w formacie JSON.
- przeniesienia listy książek do partiala, który wyrenederuje zawartość
tablicy przekazanej w zmiennej lokalnej
- opcji renderowania w kontrolerze kodu JavaScript, który przeładuje
  nam content w dokumencie HTML

## Preludium

Przed przystąpieniem do pracy nad naszym kodem, ściągnijmy sobie
potrzebne pliki `js` i `css` z [tej
podstrony](http://easyautocomplete.com/download)

W przypadku powyższej biblioteki, będą potrzebne wyłącznie dwa pliki.
Wypakujmy archiwum `zip` i przekopiujmy potrzebne rzeczy do naszego projektu w
następujące miejsca:
```
app/assets/javascripts/vendor/jquery.easy-autocomplete.js
app/assets/stylesheets/easy-autocomplete.css
```

## Działamy!

1. Dodajemy nasz nowy, bazowy kontroler API. Umieszczamy go w module `API::V1`.
   Nasz kontroler dziedziczyć będzie z `ActionController::API`. Jest to
   klasa, która pozwala tworzyć minimalistyczne kontrolery. Zapewni nam to
   dużą szybkość działania i mniejsze obciążenie pamięci aplikacji, niż
   w przypadku dziedziczenia po `ActionController::Base`.
   [Link do oficjalnej dokumentacji
ActionController::API](http://api.rubyonrails.org/classes/ActionController/API.html)

![base api controller](./3.png?raw=true "base api controller")

2. Dodajemy nowy kontroler w namespace naszego API. Będzie on
   dziedziczyć po klasie, którą stworzyliśmy w punkcie 1. Tworzymy w nim
   callback `#check_login`, aby zabezpieczyć się przed nieautoryzowanym
   dostępem:

![api books controller](./4.png?raw=true "api books controller")

   Jeżeli nie dodamy naszego callbacku, będzie możliwe uzyskanie listy
książek bez autoryzacji, zwykłym poleceniem `curl`:

![curl 200](./12.png?raw=true "curl 200")

   Użycie callbacku sprawdzającego wynik wywołania metody `#current_user` zapewnia nam
   ochronę przed nieautoryzowanym dostępem. Wywołanie polecenia `curl`
   zwróci nam następujący komunikat z API:

![curl 401](./13.png?raw=true "curl 401")

3. Aby udostępnić nasz nowy zasób musimy utworzyć ścieżki. Dodajemy też
   ścieżkę do metody `filter` kontrolera `BooksController`, będzie nam
   za moment potrzebna:

![routes changes](./10.png?raw=true "routes changes")

4. Tworzymy nowy partial z formularzem który posłuży nam do wyszukiwania
   naszych książek. Będzie on submitowany metodą `GET` do metody `#filter`
   kontrolera `BooksController` (określa to metoda helperowa `filter_path`).
   Parametry `remote: true` oraz `format: js` sprawią, że w odpowiedzi na submit
   formularza, Railsy wyrenderują odpowiedź w formacie JavaScript.

![find book partial](./6.png?raw=true "find book partial")

   Oczywiście przyda nam się też fragment css, który posłuży nam do ładnego
   ostylowania pól formularza umieszczonych 'inline' wraz z ikonką na
   naszym nowym guziku:

![home.css](./2.png?raw=true "home.css")

   Będzie nam też potrzebny fragment kodu JavaScript odpowiedzialnego za
   naszą funkcjonalność autouzupełniania pól w formularzu.
   Poniższy kod sprawi, że pobrana przez nas wtyczka `easyautocomplete`
   przy każdym kolejnym, wpisanym przez użytkownika znaku
   będzie się komunikować z naszym API w celu otrzymania listy książek w
   formacie JSON. Jest tam również event handler usprawniający pracę
   formularza. Sprawia on, że po autouzupełnieniu jednego z trzech pól, pozostałe
   pozostaną przed submitem wyczyszczone. Reszta już klasycznie: kliknięcie w guzik
   (czyli akcja `submit`) spowoduje przesłanie zapytania `GET` z parametrami z
   formularza.

![books.js](./1.png?raw=true "books.js")

5. Renderujemy nasz nowy partial `find_book` w template `books/index.html.erb`.
   Przenosimy też naszą tabelkę z książkami do osobnego partiala. Będzie nam
   tam potrzebna, ponieważ chcemy jej użyć w dwóch miejscach: po
   wywołaniu  akcji `#index`, oraz akcji `#filter`, która będzie nam
   dynamicznie podmieniać tę tabelkę w zależności od tego, co wpiszemy
   w nasze pola wyszukiwania. W miejscu tabelki użyjemy więc metody
   `#render`, przekazując jej zmienną lokalną `books`.

![books index changes](./9.png?raw=true "books index changes")

   Partial kopiujemy do `views/books/elements/_table` i podmieniamy
   odwołanie do zmiennej instancji `@books` na zmienną lokalną `books`,
   która będzie zawsze przekazywana tutaj przy renderowaniu partiala.
   Będzie ona tablicą zawierającą obiekty naszych książek. W przypadku wywołania
   akcji `#index` w `BooksController` w tej tablicy będą wszystkie
   książki (czyli po staremu ;)).

![books table parial](./7.png?raw=true "books table partial")

6. Brakującym elementem są zmiany  w kontrolerze `BooksController`. Potrzebujemy
   metody `filter`, która wyrenderuje nasz nowy partial `books/filter`,
wypełniając go przefiltrowanymi danymi z metody `#filter_books` (czyli:
trzeba przekazać do partiala tablicę z kolekcją książek pasującą do
zadanych kryteriów).

Kluczową rzeczą jest tutaj tzw. permitowanie parametrów, niezbędne do
wywołania metody `Book.where`. Pozwalamy tylko na parametry wymienione w
wyłaniu: `params.permit(:title, :isbn, :category_id, :category_name)`.

Troszkę skomplikowanie wygląda metoda `#filter_params`, ale nie obawiaj
się, to nic strasznego ;) Ta metoda ma nam zwrócić hash potrzebny w wywołaniu `Book.where`.
Będzie mieć on przykładową postać: `{title: 'tytuł', isbn: 'isbn', category_id: '1'}`.
Bystre oko zauważy, że użytkownik nie wpisuje przecież numeru ID kategorii, a tylko jej nazwę!
Trzeba więc zwrócić numer ID na podstawie nazwy kategorii. To właśnie do tego celu
użyjemy: `Category.find_by_name`. Na otrzymanym stąd obiekcie wywołamy następnie `#present?`,
aby zabezpieczyć się przed brakiem wyników (czyli de facto brakiem ID).

![books controller changes](./5.png?raw=true "books controller changes")

7. Trochę magii, czyli renderowanie kodu JavaScript. Framework umożliwia
   renderowanie js na podstawie szablonów `*.erb`. Zrobimy to w nowym
   template `books/filter.js.erb`.

![filter.js.erb](./8.png?raw=true "filter.js.erb")

   Nasz kodzik spowoduje zastąpienie elementu o klasie
`.x-books-table-container` fragmentem html wyrenderowanym z partiala
`books/elements/table` któremu przekazana zostanie zmienna lokalna
`books`. Tajemnicza metoda `#j` okalająca nasze wywołanie `#render` to
tak naprawdę alias metody `#escape_javascript` służącej do poprawnego
umieszczenia kodu html w wywołaniu metody jQuery `#html`

## Epilog

Gotowe! Możemy cieszyć się nową, wygodną funkcjonalnością :)

![ficzerek](./11.png?raw=true "ficzerek")

Co ważne, "pobocznym" efektem wykonania zadania jest bazowa struktura API, którą można
łatwo rozbudować o kolejne zasoby, zgodnie z
[REST](http://whatisrest.com/rest_architectural_goals/index)


by Kazimierz Sołtysik
