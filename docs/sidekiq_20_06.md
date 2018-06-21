# Zadania w tle: wyślij maila, kiedy zbliża się termin!

<a href="#higiena-pracy-">Higiena pracy</a><br>
<a href="#co-chcemy-uzyska%C4%87">Co chcemy uzyskać?</a><br>
<a href="#og%C3%B3lne-kroki-do-podj%C4%99cia">Ogólne kroki do podjęcia</a><br>
<a href="#mail-informuj%C4%85cy-o-zbli%C5%BCaj%C4%85cym-si%C4%99-terminie-oddania-ksi%C4%85%C5%BCki">Maile informujące o zbliżającym się terminie oddania książki</a><br>
<a href="#konfiguracja-zada%C5%84-w-tle---sidekiq">Konfiguracja zadań w tle - Sidekiq</a><br>
<a href="#konfiguracja-zada%C5%84-w-tle---delayedjob">Konfiguracja zadań w tle - DelayedJob</a><br>
<a href="#gdzie-by%C5%82-b%C5%82%C4%85d">Gdzie był błąd?</a><br>

## _Higiena pracy_ ;)

Zadanie wykonuj na osobno stworzonym **branchu**, a następnie po wypushowaniu go stwórz _pull request_ na Githubie<br>
Jeżeli będziesz próbował _DelayedJob_ oraz _Sidekiqa_ - postaraj się posłużyć nimi na osobnych branchach<br>
Jeżeli będziesz miał problem ze stworzeniem PR-a (czy oczywiście jakikolwiek inny ;) ) - wołaj mentora! <br>
...to wszystko po to, żebyśmy potem mogli łatwiej rzucić okiem na Twoje zmiany, Twój kod i dać ( _beloved_ ) _feedback_ :)
<br>
<br>
W ramach tego tutorialu postaramy się przeprowadzić Was dokładnie **krok po kroku**.<br>
Postaraj się jednak **nie kopiować kodu** - od kopiowania jeszcze nikt niczego się nie nauczył ;)<br>
Oczywiście jeżeli chcesz - rozwiązuj po swojemu! Prezentowana tutaj ścieżka nie jest 'jedyna i słuszna'. Ba! kombinacje nawet są mile widziane :)<br>
Bądź jednak wyrozumiały dla mentorów - będą musieli wdrożyć się chwilę w Twój pomysł.


## Co chcemy uzyskać?

* Dzień przed terminem zwrotu wypożyczonej książki (`reservation` w statusie `TAKEN`)
  * użytkownik, który ją wypożyczył powinien dostać maila, że zbliża się termin zwrotu
  * następny user, który ją zarezerwował - że wkrótce będzie dostępna
* W tym celu w momencie wypożyczenia musimy **'zapiąć' do wykonania zadanie w tle na dzień przed oddaniem**
* To zadanie wyśle maile do obu użytkowników
* Treści maili:
  * Hej <-email->! <-date-> upływa termin oddania książki pt. <-book_title->. Prosimy - zwróć książkę w terminie! <-link do podglądu książki->
  * Hej <-email->! <-date-> upływa termin oddania książki pt. <-book_title->, którą zarezerwowałeś w systemie. Już niedługo możesz ją odebrać! <-link do podglądu książki->

## Ogólne kroki do podjęcia

* Przygotować **mailer(y)**, które obsłużą wysyłkę wskazanych wiadomości (nie cudujmy z wyglądem ;) )
* Skonfigurować obsługę zadań w tle
  * Jeżeli masz w środowisku zainstalowanego Redisa lub jego instalacja nie sprawi Ci dużego problemu (10min!) - proponujemy **Sidekiq'a**
  * Wiemy jednak, że na części środowisk to nie jest takie łatwe - śmiało przepnij się na **DelayedJob**, to też świetne narzędzie
* **dla nadgorliwych** po ukończeniu 'podstawowego' zadania ;)
  * kolejkujemy workera przy wypożyczeniu na dzień przed terminem zwrotu. Co się stanie, jeżeli między czasie ktoś odda książkę? Zabezpiecz przed tym mechanizm
  * spróbuj wykorzystać do wykonania zadania ActiveJob używając odpowiednio jako `queue_adapter` Sidekiq'a (https://github.com/mperham/sidekiq/wiki/Active-Job) lub Delayed Job (http://bica.co/2015/03/08/howto-using-activejob-with-delayedjob/)
  * napisz spek dla tego JOB-a
  * użyj na osobnych branchach Sidekiq'a i DelayedJob. Pobaw się ich __performance__, znajdź wady i zalety z Twojego punktu widzenia


## Mail informujący o zbliżającym się terminie oddania książki

Podstawowy tutorial mailerowy został przedstawiony <a href="https://github.com/infakt/atelier_june_2018/blob/homework/docs/homework_13_06_mailer.md">tutaj</a>, dlatego w tym wpisie nie będziemy wchodzili w teoretyczne szczegóły z nim związane.

### Konfiguracja _action_mailer_ w aplikacji

* Jeżeli wykonałeś zadanie domowe i wysyłają Ci się maile - możesz pominąć śmiało ten element
* Jeżeli zadanie domowe 'nie siadło' - przepnij się na gotowy branch z rozwiązaniem, przyjrzyj się czy masz wszystko skonfigurowane (patrz: <a href="https://github.com/infakt/atelier_june_2018/blob/homework/docs/homework_13_06_mailer.md">opis</a>)
* gotowy <a href='https://github.com/infakt/atelier_june_2018/tree/mailer_solution'>branch z rozwiązaniem</a>
* instrukcja <a href='https://github.com/infakt/atelier_june_2018/wiki/Przepi%C4%99cie-si%C4%99-na-gotowe-rozwi%C4%85zanie-(branch-startowy-do-dalszej-cz%C4%99%C5%9Bci-warsztat%C3%B3w)'> przepinania </a>

### Generowanie mailera - BookNotifier

* Tworzymy nowy **rodzaj mailera** - **_BookNotifier_**, który będzie odpowiedzialny za maile notyfikujące o zdarzeniach związanych z książkami
* Ten jeden mailer będzie na razie obsługiwał wysyłkę dwóch maili opisanych w zadaniu
```ruby
rails generate mailer BookNotifier
```
* to wywołanie powinno utworzyć nam odpowiednie pliki w tym klasę mailera, w ramach której dodamy wysyłkę maili

**Mail 'ej, oddaj książkę' - mail itself**

* mail do użytkownika, który ma książkę w statusie `taken`, której jutro upływa termin zwrotu
* jakich informacji potrzebujemy, żeby go wysłać?
  * do kogo wysłać maila (mail usera)
  * co to za książka - musimy w mailu podać jej tytuł, termin zwrotu oraz adres do podglądu
* te wszystkie informacje możemy mieć z samego obiektu książki, więc tylko ten obiekt przekażemy do wywołania maila
```ruby
class BookNotifierMailer < ApplicationMailer

  def book_return_remind(book)
    @book = book
    @reservation = book.reservations.find_by(status: "TAKEN")
    @borrower = @reservation.user

    mail(to: @borrower.email, subject: "Upływa termin zwrotu książki #{@book.title}")
  end
end
```
* Możemy spróbować wysłać teraz maila z konsoli railsowej
```ruby
> book = Reservation.find_by(status: "TAKEN").book
> BookNotifierMailer.book_return_remind(book).deliver_now
#...
ActionView::MissingTemplate: Missing template book_notifier_mailer/book_return_remind with "mailer". Searched in:
  * "book_notifier_mailer"

  from app/mailers/book_notifier_mailer.rb:7:in `book_return_remind'
  from (irb):8
```
...ale przecież nic z tego, bo nie mamy widoku ;)

**Mail 'ej, oddaj książkę' - widok**

Dodajemy widok (HTML oraz tekstowy)

```ruby
# app/views/book_notifier_mailer/book_return_remind.html.erb
<h2>Hej <%= @borrower.email %></h2>
<p>
  <%= @reservation.expires_at %> upływa termin oddania książki pt. <%= @book.title %>. Prosimy - zwróć książkę w terminie!<br>
  <%= link_to "Przejdź do książki", book_url(@book.id, host: "localhost:3000") %>
</p>
```
```ruby
# app/views/book_notifier_mailer/book_return_remind.text.erb
Hej <%= @borrower.email %>
<%= @reservation.expires_at %> upływa termin oddania książki pt. <%= @book.title %>. Prosimy - zwróć książkę w terminie!
<%= link_to "Przejdź do książki", book_url(@book.id, host: "localhost:3000") %>
```

* odpalmy teraz wysyłkę z konsoli `BookNotifierMailer.book_return_remind(book).deliver_now` i odwiedźmy `http://localhost:1080/`

**BANG!**

**Teraz należy dodać odpowiednio drugiego maila do wysłania**
```ruby
class BookNotifierMailer < ApplicationMailer

  def book_return_remind(book)
    #...
  end

  def book_reserved_return(book)
    #...
  end
end
```

## Konfiguracja zadań w tle - Sidekiq

https://github.com/mperham/sidekiq
<br>
### Instalacja Redisa

Jak wspomnieliśmy na prezentacji - Sidekiq działa w oparciu o Redisa.
<a href='https://github.com/infakt/atelier_june_2018/wiki/Instalacja-Redisa'>Instrukcja instalacji Redisa</a>

### Dodanie Sidekiq'a do projektu

Dodamy teraz Sidekiq'a i przykładowy worker, który będzie wykonywał tylko `touch` na wskazanej książce, czyli będzie tylko podbijał jej `updated_at`, żebyśmy zobaczyli czy _u mnie działa_

* sidekiq jest gemem więc...
```ruby
# Gemfile
...
gem 'sidekiq'
...
```

* następnie tworzymy **worker** czyli właśnie to zadanie w tle
  * `app/workers`
  * worker jest **klasą** do której musimy zaincludować `Sidekiq::Worker`
  * w workerze koniecznie musi pojawić się metoda `perform` -  to zawsze ona będzie wykonywała logikę zadania w tle
  * ten perform może dostawać **argumenty** ale uwaga! nie mogą to być obiekty! Dlaczego? Flow jest takie, że kolejkujemy zadanie w Redisie, a dopiero z Redisa zaciąga sobie Sidekiq. Redis jest słownikiem klucz - wartość i chociaż może przechowywać różne typy wartości - to nie ogarnie obiektów ;) Możemy za to przekazać ID i odnaleźć obiekt.

```ruby
# app/workers/test_touch_worker.rb

class TestTouchWorker
  include Sidekiq::Worker

  def perform(book_id)
    Book.find(book_id).touch
  end
end
```

* teraz w terminalu musimy **odpalić sidekiq'a** przy pomocy polecenia `sidekiq`; powinniśmy zobaczyć dzielnego karatekę ;)

![alt text](https://monosnap.com/file/3Ufhc6sVFHhBsFl8MXKjLOLxqvYxtR.png "Sidekiq running")

* PS. Testowo możesz **wyłączyć serwer Redisa i zobaczyć co się stanie** - powinienś wylądować z błędem `Error connecting to Redis on 127.0.0.1:6379 (Errno::ECONNREFUSED)`

* mamy działającego Redisa, mamy śmigającego Sidekiq'a, który się z nim łączy - czas **odpalić nasz worker**, z konsoli railsowej
```ruby
book1 = Book.first
book2 = Book.second
book3 = Book.third

TestTouchWorker.perform_in(1.minutes, book1.id)
#odpali zadanie za minutę, dla książki book1

TestTouchWorker.perform_at(Time.now+2.minutes, book2.id)
#inne wywołanie - odpali zadanie za 2 min, dla książki book2

TestTouchWorker.perform_async(book3.id)
#zakolejkuje a następnię odpali zadanie "w wolnej chwili", dla książki book3
```

* każde wywołanie powinno "zwracać" ID zakolejkowanego workera
* w logach sidekiq'a powinny po kolei, w 'odpowiednich' momentach -  wpadać nam te taski
```
... TID-our0dgns4 TestTouchWorker JID-7ec08d749cfcb9db737c16f1 INFO: start
... TID-our0dgns4 TestTouchWorker JID-7ec08d749cfcb9db737c16f1 INFO: done: 0.711 sec
... TID-our0ynf9s TestTouchWorker JID-5d4e2acdef41fb02eb203ea7 INFO: start
... TID-our0ynf9s TestTouchWorker JID-5d4e2acdef41fb02eb203ea7 INFO: done: 0.016 sec
```

**BANG!**
Działa! Usuńmy więc naszego testowego workera :)

### Zaraz zaraz... obiecaliscie jakiś PANEL!

Mówisz-masz!<br>
* Dodajmy do routingu
```ruby
#config/routes.rb
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq'
```
* odpalmy localhost:3000/sidekiq... i panel jak się patrzy!<br>
![alt text](https://monosnap.com/file/HArkfJAnmonDbCDTOs69gOsyZIaixC.png "sidekiq panel")

### Worker wysyłający maile do użytkowników

Jak pamiętasz, do wysyłki odpowiedniego maila, do odpowiednich osób, potrzebowaliśmy jedynie **obiektu książki**.<br>
Jedyne w takim razie co potrzebujemy przekazać do workera to znowu **ID książki**, której termin wygasa.

* Tworzymy więc nowego workera
```ruby
# app/workers/book_reservation_expire_worker.rb
class BookReservationExpireWorker
  include Sidekiq::Worker

  def perform(book_id)
  end
end
```

* A następnie go wypełniamy. **Uwaga** - przypominam, że do mailera potrzebujemy przekazać już faktyczny obiekt, a nie ID
```ruby
# app/workers/book_reservation_expire_worker.rb
class BookReservationExpireWorker
  include Sidekiq::Worker

  def perform(book_id)
    book = Book.find(book_id)
    BookNotifierMailer.book_return_remind(book).deliver
    BookNotifierMailer.book_reserved_return(book).deliver
  end
end
```

### Wpięcie workera w aplikację

* Workera powinniśmy wpiąć **przy wypożyczeniu książki** na dzień przed `expires_at` rezerwacji
* **Uwaga** - dalsza część zależy od tego, czy wykorzystujesz mechanizm `ReservationHandler` z poprzednich warsztatów, czy akcja wypożyczenia książki ma nadal miejsce w modelu
* w tym tutorialu na wszelki wypadek zakładam wypożyczanie z modelu ;) Jeżeli potrzebujesz wpiąć w `ReservationHandler` nie powinno to sprawić większego problemu, ale możesz też śmiało zagadać którego z mentorów
<br>
<br>

* Akcja wypożyczenia w modelu
```ruby
# app/models/book.rb
...
def take(user)
  return unless can_take?(user)

  if available_reservation.present?
    available_reservation.update_attributes(status: 'TAKEN')
  else
    reservations.create(user: user, status: 'TAKEN')
  end
end
...
```
* mamy tutaj dwa przypadki - pierwszy **kiedy jest jakaś rezerwacja dostępna** - `available_reservation.present?`
  * w takiej sytuacji **mamy dostęp do obiektu rezerwacji** - `available_reservation`
  * z rezerwacji - możemy wyciągnąć **książkę** oraz jej **_deadline_**
  * ...a to znaczy, że możemy **odpalić workera dla danej książki, na dzień przed deadlinem!**

```ruby
# app/models/book.rb
...
def take(user)
  return unless can_take?(user)

  if available_reservation.present?
    ::BookReservationExpireWorker.perform_at(available_reservation.expires_at-1.day, available_reservation.book_id)
    available_reservation.update_attributes(status: 'TAKEN')
  else
    reservations.create(user: user, status: 'TAKEN')
  end
end
...
```

* drugi przypadek - nie ma żadnej rezerwacji - tworzymy nową
  * przy tworzeniu rezerwacji - musimy ją sobie gdzieś zapisać, żeby móc z niej skorzystać, jak w poprzednim przypadku
  * następnie, mając ją pod ręką - możemy wykonać tę samą logikę co w poprzednim przykładzie

```ruby
# app/models/book.rb
...
def take(user)
  return unless can_take?(user)

  if available_reservation.present?
    ::BookReservationExpireWorker.perform_at(available_reservation.expires_at-1.day, available_reservation.book_id)
    available_reservation.update_attributes(status: 'TAKEN')
  else
    reservation = reservations.create(user: user, status: 'TAKEN')
    ::BookReservationExpireWorker.perform_at(reservation.expires_at-1.day, reservation.book_id)
  end
end
...
```

* ...wyrzućmy to jeszcze dla przyzwoitoiści do metody prywatnej, żeby nie kłuło w oczy powtórzenie logiki :)

```ruby
# app/models/book.rb
...
def take(user)
  return unless can_take?(user)

  if available_reservation.present?
    perform_expiration_worker(available_reservation)
    available_reservation.update_attributes(status: 'TAKEN')
  else
    perform_expiration_worker(reservations.create(user: user, status: 'TAKEN'))
  end
end
...
private

def perform_expiration_worker(res)
  ::BookReservationExpireWorker.perform_at(res.expires_at-1.day, res.book_id)
end
```

* Odpalamy i... efektu szybko nie zobaczymy, bo przecież worker powinien odpalić się dopiero za kilkanaście dni; **Zajrzyjmy więc do panelu, sprawdźmy czy tam jest i "przyspieszmy" dodanie go do kolejki**

![alt text](https://monosnap.com/file/XtD1KvRIpGqHzFuOglm2l6zhzzoC8Q.png "Sidekiq add to queue")

* **...no i się wywaliło** :) Dlaczego? sprawdźmy w panelu
* skoro się wywaliło - to sidekiq będzie **próbował wykonać jeszcze raz**
* więcej info znajdziemy w takim razie **w zakładce _Prób_**

![alt text](https://monosnap.com/file/bhqLqwcTZ6q9kDdUwTMmjsgwbLhd4r.png "Retry")

* Zanim przeczytasz skąd się wziął błąd - spróbuj pokminić
  * `user for nil:NilClass`? Gdzie wywołujemy user-a?
  * spróbuj w konsoli odpalić oba mailery wykonywane w workerze z tą książką, która wpada do workera; zobacz przy którym i gdzie się wywala
  * ...gdzie jest błąd - podrzucę pod koniec tutoriala ;)

## Konfiguracja zadań w tle - DelayedJob

Warto przejrzeć: https://github.com/collectiveidea/delayed_job <br>
_DelayedJob_ oferuję sporo **różnych sposobów wywołań** i będziemy omawiali wszystkich.<br>
Ich użycie zależy od kontekstu i potrzeby.

### Konfiguracja-migracja!

* W naszym przypadku potrzebujemy **dwóch gemów**
  * gem delayed_job pod `ActiveRecord` - `delayed_job_active_record` - bo to `ActiveRecord` jest naszą nakładką na bazę
  * `daemons` - żeby móc odpalać delayed_job jako proces w tle

```ruby
gem 'delayed_job_active_record'
gem 'daemons'
```
* Kolejnym krokiem jest **zbudowanie tabeli do kolejkowania zadań**
```ruby
rails generate delayed_job:active_record
rake db:migrate
```
* polecenie to wygeneruje nam też skrypt do odpalenia DJ; musimy więc jeszcze odpalić!
```ruby
bin/delayed_job start
> delayed_job: process with pid XXXX started.
```

### Magiczna metoda `delay`

* Dlaczego taka magiczna? ano dlatego, że możemy ją... **po prostu użyć, żeby przenieść wykonanie czegoś w tło**
* Przykład: teraz wypożyczenie książki polega na wywołaniu
```ruby
book.take(user)
```
* możemy w bardzo łatwy sposób przenieść wykonanie akcji wypożyczenia w tło (co, poza ćwiczeniem, specjalnego sensu nie ma :) ), powiedzmy za dwie minuty
```ruby
book.delay(run_at: Time.now+2.minutes).take(user)
```

* ...i to wszystko! żeby sprawdzić, że zadanie się zakolejkowało, możemy sprawdzić **zawartość bazy**, bo to przecież bazie trzymamy kolejkę zadań
```ruby
Delayed::Job.all
=> #<ActiveRecord::Relation [#<Delayed::Backend::ActiveRecord::Job id: 5, priority: 0, attempts: 0, handler: "--- !ruby/object:Delayed::PerformableMethod\nobject...", last_error: nil, run_at: "...", locked_at: nil, failed_at: nil, locked_by: nil, queue: nil, created_at: "...", updated_at: "...">]>
 ```

### Wpięcie wysyłki maili jako zadań w tle - `delay`

* Maile powinniśmy wpiąć do wysłania **przy wypożyczeniu książki** na dzień przed `expires_at` rezerwacji
* **Uwaga** - dalsza część zależy od tego, czy wykorzystujesz mechanizm `ReservationHandler` z poprzednich warsztatów, czy akcja wypożyczenia książki ma nadal miejsce w modelu
* w tym tutorialu na wszelki wypadek zakładam wypożyczanie z modelu ;) Jeżeli potrzebujesz wpiąć w `ReservationHandler` nie powinno to sprawić większego problemu, ale możesz też śmiało zagadać którego z mentorów


* Akcja wypożyczenia w modelu
```ruby
# app/models/book.rb
...
def take(user)
  return unless can_take?(user)

  if available_reservation.present?
    available_reservation.update_attributes(status: 'TAKEN')
  else
    reservations.create(user: user, status: 'TAKEN')
  end
end
...
```
* Jak będzie wyglądała wysyłka maili przy pomocy DJ?
```ruby
::BookNotifierMailer.delay(run_at: ...).book_return_remind(book)
::BookNotifierMailer.delay(run_at: ...).book_reserved_return(book)
```
* Potrzebujemy przekazać książkę oraz datę wysyłki mailera
* mamy tutaj dwa przypadki - pierwszy **kiedy jest jakaś rezerwacja dostępna** - `available_reservation.present?`
  * w takiej sytuacji **mamy dostęp do obiektu rezerwacji** - `available_reservation`
  * z rezerwacji - możemy wyciągnąć **książkę** oraz jej **_deadline_**
  * ...a to znaczy, że możemy **odpalić mailery dla danej książki, na dzień przed deadlinem!**

```ruby
# app/models/book.rb
...
def take(user)
  return unless can_take?(user)

  if available_reservation.present?
    ::BookNotifierMailer
      .delay(run_at: available_reservation.expires_at-1.day)
      .book_return_remind(available_reservation.book)
    ::BookNotifierMailer
      .delay(run_at: available_reservation.expires_at-1.day)
      .book_reserved_return(available_reservation.book)
    available_reservation.update_attributes(status: 'TAKEN')
  else
    reservations.create(user: user, status: 'TAKEN')
  end
end
...
```

* drugi przypadek - nie ma żadnej rezerwacji - tworzymy nową
  * przy tworzeniu rezerwacji - musimy ją sobie gdzieś zapisać, żeby móc z niej skorzystać, jak w poprzednim przypadku
  * następnie, mając ją pod ręką - możemy wykonać tę samą logikę co w poprzednim przykładzie

```ruby
# app/models/book.rb
...
def take(user)
  return unless can_take?(user)

  if available_reservation.present?
    ::BookNotifierMailer
      .delay(run_at: available_reservation.expires_at-1.day)
      .book_return_remind(available_reservation.book)
    ::BookNotifierMailer
      .delay(run_at: available_reservation.expires_at-1.day)
      .book_reserved_return(available_reservation.book)
    available_reservation.update_attributes(status: 'TAKEN')
  else
    reservation = reservations.create(user: user, status: 'TAKEN')
    ::BookNotifierMailer
      .delay(run_at: reservation.expires_at-1.day)
      .book_return_remind(reservation.book)
    ::BookNotifierMailer
      .delay(run_at: reservation.expires_at-1.day)
      .book_reserved_return(reservation.book)
  end
end
...
```
* mały refaktor, żeby nasz kod nie straszył dzieci
```ruby
# app/models/book.rb
...
def take(user)
  return unless can_take?(user)

  if available_reservation.present?
    send_mailers(available_reservation)
    available_reservation.update_attributes(status: 'TAKEN')
  else
    send_mailers(reservations.create(user: user, status: 'TAKEN'))
  end
end

private

def send_mailers(res)
  remind_date = res.expires_at - 1.day
  ::BookNotifierMailer.delay(run_at: remind_date).book_return_remind(res.book)
  ::BookNotifierMailer.delay(run_at: remind_date).book_reserved_return(res.book)
end
...
```
* możemy teraz rzucić okiem czy nasze wykonania się zakolejkowały
```ruby
Delayed::Job.all
```
* ...i możemy spróbować **wymusić wykonanie** wszystkich zakolejkowanych zadań, żeby nie czekać 2tyg przy pomocy `invoke_job`
```ruby
Delayed::Job.all.each(&:invoke_job)
> BookNotifierMailer#book_reserved_return: processed outbound mail in 9.3ms
NoMethodError: undefined method `user' for nil:NilClass
  from app/mailers/book_notifier_mailer.rb:14:in `book_reserved_return'
```
* ...ups... to się posypało... Spróbuj zastanowić się dlaczego w `book_reserved_return` dla danej książki wpadamy w `user for nil:NilClass`; gdzie jest błąd podrzucę pod koniec tutoriala


## Gdzie był błąd?

* `undefined method `user' for nil:NilClass`
* próbowalismy w mailu `book_reserved_return` wywołać użytkownika na **jakiejś rezerwacji w statusie `RESERVED`
* w ramach ćwiczeń chcieliśmy od razu zobaczyć efekty, więc zapinaliśmy wykonanie zadań w tle **od razu po akcji `take`**, po czym odpalaliśmy na siłę, już teraz te zadania
* ...'już teraz' - czyli nie było szansy, żeby pojawiła się jakaś rezerwacja `RESERVED`!
* musimy zabezpieczyć kod na wypadek **braku oczekujących rezerwacji**, bo w życiu - też może okazać się, że aż do zwrotu - nikt książki nie zarezerwuje :)
