# Zadania w tle: wykorzystanie gotowego rozwiązania - SIDEKIQ

* **Rozwiązanie zakłada, że masz zainstalowanego lokalnie REDISA** - tego nie damy rady zrobić zdalnie za Ciebie ;)
* gotowe rozwiązanie <a href="https://github.com/infakt/atelier_june_2018/blob/sidekiq_20_06/docs/sidekiq_20_06.md">zadania</a>
* rozwiązanie dostępne na branchu <a href='https://github.com/infakt/atelier_june_2018/pull/10/files'>background_jobs_solution_SIDEKIQ</a>
* w ramach tego rozwiązania **rezygnujemy z mailcatchera** - oprzemy się o <a href='https://devblast.com/b/jutsu-9-send-emails-development-letter-opener'>letter_opener</a>
* kroki do podjęcia
  * lokalne przepięcie się na brancha zdalnego
  * odpalenie potrzebnych konfiguracji
  * przetestowanie rozwiązania

Przypominam ideę zadania:

* Dzień przed terminem zwrotu wypożyczonej książki (`reservation` w statusie `TAKEN`)
  * użytkownik, który ją wypożyczył powinien dostać maila, że zbliża się termin zwrotu
  * następny user, który ją zarezerwował - że wkrótce będzie dostępna
* W tym celu w momencie wypożyczenia musimy **'zapiąć' do wykonania zadanie w tle na dzień przed oddaniem**
* To zadanie wyśle maile do obu użytkowników
* Treści maili:
  * Hej <-email->! <-date-> upływa termin oddania książki pt. <-book_title->. Prosimy - zwróć książkę w terminie! <-link do podglądu książki->
  * Hej <-email->! <-date-> upływa termin oddania książki pt. <-book_title->, którą zarezerwowałeś w systemie. Już niedługo możesz ją odebrać! <-link do podglądu książki->

## Lokalne przepięcie się na zdalne rozwiązanie

Ogólnie idea opisana jest <a href='https://github.com/infakt/atelier_june_2018/wiki/Przepi%C4%99cie-si%C4%99-na-gotowe-rozwi%C4%85zanie-(branch-startowy-do-dalszej-cz%C4%99%C5%9Bci-warsztat%C3%B3w)'>tutaj</a>

W tym konkretnym przypadu:
* Zdalne repozytoria - załączone repozytorium inFak
  * sprawdzamy listę zdalnych repo dla projektu:
```
$ git remote -v
```
  * jeżeli widzisz **cztery wierze - dwa origin i dwa infaktowe** - nie musisz ponownie dodawać repo dostarczone przez inFakt
  * jeżeli widzisz **tylko dwa wiersze origin** - musimy dodać repo dostarczone przez inFakt, nazwyjąc je np. infakt_repo:
```
$ git remote add infakt_repo https://github.com/infakt/atelier_june_2018.git
```
  * teraz lista powinna zawierać **cztery wiersze - dwa origin, dwa infakt_repo**
```
$ git remote -v
origin  https://github.com/YOUR_USERNAME/YOUR_FORK.git (fetch)
origin  https://github.com/YOUR_USERNAME/YOUR_FORK.git (push)
infakt_repo https://github.com/infakt/atelier_june_2018.git (fetch)
infakt_repo https://github.com/infakt/atelier_june_2018.git (push)
```
* przepięcie się na gotowe rozwiązanie - branch `background_jobs_solution_SIDEKIQ`
  * `$ git remote update`
  * `$ git checkout infakt_repo/background_jobs_solution_SIDEKIQ`
  * `git checkout -b background_jobs_solution_SIDEKIQ_local`
  * gdzie `background_jobs_solution_SIDEKIQ_local` to lokalna nazwa brancha, u Ciebie, dowolna

## Odpalenie potrzebnych konfiguracjo-migracji

* Sidekiq to **gem**, który kolejkuje zadania w **Redisie**
* dlatego instalujemy gem
`$ bundle install`
* odpalamy serwer Redisa (<a href='https://github.com/infakt/atelier_june_2018/wiki/Instalacja-Redisa'>szczegóły dotyczące korzystania z Redisa</a>)
* odpalamy Sidekiq'a
`$ sidekiq`
* następnie odpalamy/restartujemy serwer naszej aplikacji - teraz wypożyczenie książki powinno **kolejkować wykonanie zadania**

## Przetestowanie rozwiązania

* odpal serwer aplikacji
* jednym użytkownikiem **wypożycz książkę**
* drugim użytkownikiem **zarezerwuj tę wypożyczoną książkę**
* możemy zobaczyć listę zakolejkowanych zadań pod adresem `localhost:3000/sidekiq`
<img src="https://monosnap.com/image/76Gz6mZr3gbMk0kg90xIh0UPy1nv5h.png">
* następnie, zamiast czekac tydzień - wykonamy zadanie już teraz:
<img src="https://monosnap.com/image/hBbCpY8NHLtBSJFMqRhtOdLm7hOo4F.png">
* powinny otworzyć Ci się w przeglądarce karty z wysłanymi mailami
