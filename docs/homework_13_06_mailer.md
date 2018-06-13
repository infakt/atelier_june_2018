# Pierwszy mailer w aplikacji: _książka wypożyczona_!

## Co chcemy uzyskać?

**Po wypożyczeniu książki (akcja `take`) użytkownik ma otrzymać z naszej aplikacji maila potwierdzającego: _Wypożyczyłeś książkę XXX_**

* Informacje do zawarcia w mailu: tytuł książki (w tytule maila), jej szczegółowe dane, termin zwrotu
* Wygląd maila: dowolny, prosty szablon HTML
* Link do podglądu książki w aplikacji
* Nadawcę możesz ustawić jako `warsztaty@infakt.pl`
* **Na kolejnych spotkaniach, w innych ćwiczeniach będziemy wykorzystywali również maile, dlatego wykonanie tego zadania ułatwi pracę w dalszej części warsztatów**

## Jak to zrobić?

Potrzebujemy

* Stworzyć odpowiedni mailer
* Stworzyć widok maila (`app/views`)
* Wpiąć się z wysyłką maila w odpowiednie miejsce aplikacji
* Skonfigurować wysyłkę

W ramach tego tutorialu postaram się opisać jak to wszystko zrozumieć i osiągnąć.
Możesz też zapoznać się z [dokumentacją mailera railsowego](http://api.rubyonrails.org/v5.1/classes/ActionMailer/Base.html) lub przegrzebać internety i proponowane tutoriale i samodzielnie podjąć rękawicę!

## Mailer - ogólne informacje

* **UWAGA** poniższe opisy są _abstrakcyjne_ - mają pokazać schemat wdrażania maili, a nie jak należy wykonać zadanie domowe!
* Do obsługi wysyłki maili wykorzystujemy tzw. `mailery`, które są modelami dziedziczącymi po `ActionMailer::Base`
* ...chociaż najczęściej będziemy dziedziczyli po 'bazowym' mailerze `ApplicationMailer`, coś _a la_ `ApplicationController` dla kontrolerów
* mailery siedzą w folderze (zaskoczenie ;) ) `app/mailers`
* Dany mailer (**klasa mailera**) reprezentuje nie tyle pojedynczego maila ile jakiś **"logiczny zbiór"** maili, tak jak kontroler grupuje różne akcje związane np. z daną klasą `models`
  * `AdminMailer` - maile wysyłane do adminów, np. związane z moderacją postów
  * `ProductsNotifier` - maile notyfikujące użytkowników np. o zmianie dostępności produktów, przecenach obserwowanych, itp.
```
#app/mailers/products_notifier.rb

class ProductsNotifier < ActionMailer::Base
end
```
* Skoro klasa to zbiór - **pojedynczem mailem będzie metoda** klasy danego mailera
```
class ProductsNotifier < ActionMailer::Base
  def discount
  end

  def available
  end
end
```
* Porównanie do kontrolerów ma też związek z widokami- relacja **mailer-akcja <=> widok w folderze `app/views`**
  * app/views/products_notifier/discount.html.erb
  * app/views/products_notifier/available.html.erb
* Skoro widoki - musi być też `layout` - domyślnie w wygenerowanej apce `app/views/layouts/mailer.html.erb` i `app/views/layouts/mailer.text.erb`, ale oczywiście możemy dodawać swoje layouty dla różnych maili

## Nowy mailer w aplikacji + pierwsza _metoda mailowa_

* Żeby stworzyć nowy mailer w aplikacji możemy 
  * posłużyć się railsowym **generatorem**: `rails generate mailer ProductsNotifier`
  * albo oczywiście samodzielnie stworzyć klasę w `app/mailers` i zadbać o odpowiednie pliki (widoki, testy)
* W klasie, niezależnie od poszczególnych maili możemy określić np. wspomniany **layout** oraz **defaultowego nadawcę**
```
# app/mailers/products_notifier.rb

class ProductsNotifier < ApplicationMailer
  default from: 'warsztaty@infakt.pl
  layout 'mailer'
end
```
* Teraz możemy stworzyć **metodę odpowiedzialną za danego maila**
  * w ramach takiej metody (jak w kontrolerach ;) ) możemy zebrać dane w postaci **zmiennych instancyjnych**, które będziemy mogli **wykorzystać w widoku** maila
```
class ProductsNotifier < ApplicationMailer
  default from: 'warsztaty@infakt.pl
  layout 'mailer'

  def discount(product, user)
    @product = product
    @user = user
  end
end
```

* ...i wreszcie możemy stworzyć maila 
```
class ProductsNotifier < ApplicationMailer
  default from: 'warsztaty@infakt.pl'
  layout 'mailer'

  def discount(product, user)
    @product = product
    @user = user
    
    mail(to: user.email, subject: "Przeceniliśmy produkt!")
  end
end
```
* o metodzie `mail` i parametrach jakie może przyjmować - zapraszam po wiedzę do https://apidock.com/rails/ActionMailer/Base/mail

## Widok maila

Ok, mamy już "stworzonego" maila w mailerze, ale musi jeszcze coś iść, jakiś tekst, czy wygląd czy coś ;)

* jak wspomniałam: **widoki maili** tworzymy w `app/views/products_notifier/discount.html.erb`, `app/views/products_notifier/discount.text.erb`
* konieczny jest również **layout maila**, domyślnie `app/views/layouts/mailer.html.erb`,`app/views/layouts/mailer.text.erb`
* **uwaga** - widoki jak to widoki - mają dostęp `_url` naszych ścieżek - nie ma potrzeby przekazywać zmiennej instancyjnej w mailerze, wystarczy, ze w widoku **ustawimy odpowiedni host** ponieważ mail nie zna kontekstu przychodzącego requestu

```
# app/views/products_notifier/discount.text.erb

Cześć <%= @user.name %>!
Obserwowany przez Ciebie produkt został przeceniony! <%= link_to 'Sprawdź koniecznie', product_detail_url(@product.id, host: "localhost:3000") %>
```
* pamiętajmy, że maile, to jedne z nielicznych miejsc, gdzie mamy błogosławieństwo na _css inline style_ ;)

```
#css inline style
<div style="width:20px;height:20px;background-color:#ffcc00;"></div>
```

## Odpalenie wysyłki

Pozostało nam jeszcze odpalenie wysyłki stworzonego maila w odpowiednim miejscu:

`ProductsNotifier.discount(Product.find(xx), User.find(yy)).deliver_now`


## Konfiguracja - łyk teorii

Zaraz, zaraz. Tak łatwo nie pójdzie ;) Skąd i jak to w ogóle ma pójść? Wypadałoby jeszcze coś pokonfigurować.

* konfigurację umieszczamy w plikach środowiskowych czyli odpowiednio - `config/environments/development.rb`, `production.rb`, `test.rb`
* elementy podlegające konfiguracji to, z ważniejszych na ten moment
  * `delivery_method` czyli **sposób dostarczenia**, m.in.:
    * `smtp` - defaultowa, "tradycyjna" wysyłka
    * `test` - tryb testowy, tak naprawdę nie wysyłamy niczego - zapisujemy do tablice ActionMailer::Base.deliveries
    * `file` - zapis wysyłanych maili do pliku
  * `raise_delivery_errors` - decydujemy, czy 'walić **błędami**' podczas wysyłki, `boolean`
  *  `smtp_settings` - **ustawienia smtp** (jeżeli zdecydowaliśmy się _naprawdę_ wysyłać ;) ) - **bardzo ważny el. konfiguracji**
      * mamy tutaj kilka elementów składowych, z czego dwa "obowiązkowe" to adres i port serwera smtp
      * jak je ustawiać w jakiej sytuacji - podpowiem za chwilę
      * `address` - **adres serwera smtp**
      * `port` - port serwera smtp
      * `user_name` - nazwa użytkownika danego serwera, _if needed_
      * `password` - hasło dla tego użytkownika, _if needed_
      * `authentication` - sposób autentykacji, _if needed_
    * `default_options` - tutaj możemy ustawić defaultowe opcje, które dotąd ustawialiśmy na poziomie mailera, np. `reply_to`

## Konfiguracja - praktyka!

Ustawmy teraz przykładową konfigurację.

### Nasza propozycja - development

W trybie developmentu - proponujemy wykorzystać `mailcatcher`


https://mailcatcher.me/



Narzędzie bardzo wygodne w lokalnym użyciu, które "symuluje" wysyłkę maili i pozwala na ich podejrzenie w przeglądarce.

Kroki do wykonania
* `mailcatcher` to GEM, **ALE** - nie umieszczamy go w Gemfile'u (jest <a href="https://github.com/sj26/mailcatcher/issues/57">pewien błąd</a> w części wersji)
* z poziomu konsoli (terminala, nie konsoli railsowej), na poziomie naszej aplikacji - instalujemy gem `gem install mailcatcher -v 0.5.10` - **wersja jest bardzo ważna!**
* dalej z poziomu konsoli odpalamy serwer mailchatcher, wpisując polecenie... `mailcatcher` ;)
* będzie działał sobie w tle, jako deamon<br>
**UWAGA #linux ;)**<br>
Na Linuxie może pojawić się problem z odpaleniem `mailcatcher'a` w tle<br>
Podrzucone rozwiązanie: należy odpalić go przy pomocy `mailcatcher --foreground`

* powinniśmy mieć możliwośc odwiedzenia teraz naszej skrzynki odbiorczej - `http://localhost:1080/`
* pozostaje jeszcze konfiguracja naszej aplikacji, zgodnie z dokumentacją
```
# config/environments/development.rb
...
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = { address: "localhost", port: 1025 }
...
```

Teraz po wysłanym mailu z aplikacji - pojawi się pod adresem `http://localhost:1080/` !

### Ciekawostka - development

W wolnej chwili możesz zainteresować się trybem `letter_opener`, który pozwala na natychmiastowe otwarcie wysłanej wiadomości w oknie przeglądarki;
O gemie `letter_opener` możesz poczytać tutaj: https://devblast.com/b/jutsu-9-send-emails-development-letter-opener

### A... gdybym chciał NAPRAWDĘ wysłać maila? Np. 'z mojego' maila?

Da się zrobić!

Kluczowa jest oczywiście konfiguracja SMTP. 


Jak skonfigurować pod Twoją pocztę? Na pewno po wpisaniu w google np `configuration smtp gmail` - znajdziesz wszystkie potrzebne dane. Przykładowo, konfiguracja może wyglądać:
```
config.action_mailer.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 587,
  domain:               'gmail.com',
  user_name:            'warsztaty@infakt.pl',
  password:             'YOURPASSWORD',
  authentication:       :plain,
  enable_starttls_auto: true
}
```

**UWAGA** - pamiętaj, że podajesz tutaj swoje hasło! Tak wrażliwe dane musisz trzymać poza tym plikiem, bo trafi on do repo ;)
