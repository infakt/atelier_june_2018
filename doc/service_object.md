
# Zadanie 1
# Service Objects
## Co chcemy uzyskać ?
**Nie chcemy mieć logiki, związanej z procesem wypożyczania książek w modelu (miejscu, które trzyma reprezentację obiektów)**
## Jak to zrobić ?
Potrzebujemy stworzyć object, zadaniem którego będzie ogarnięcie akcji i walidacji, odpowiedzialnych za wypożyczanie.
## ReservationHandler
Nie mamy miejsca, gdzie moglibyśmy umieścić pliki z service obiektami. Więc tworzymy folder `app/services`
Tam tworzymy plik `reservations_handler.rb`

```ruby
class ReservationsHandler

end
```
Odpowiedzialnością tej klasy będzie ogarnięcie wypożyczeń. W tym bierze udział użytkownik, oraz właśnie książka.
To przekażemy te obiekty do metody `initialize`:
```ruby
class ReservationsHandler
  def initialize(user, book)
    @user = user
    @book = book
  end
end
```
Dodamy też attr_reader dla tych zmiennnych
```ruby
  private
  attr_reader :user, :book
```

Zaczniemy od metody `reserve`, implementacja której na ten moment znajduje się w modelu `book.rb`, a użycie w `reservations_controller.rb`
Jest to prosta metoda, która tworzy rekord `reservation`, powiązany z `book`.
```ruby

  def reserve
    return unless can_reserve?(user)

    reservations.create(user: user, status: 'RESERVED')
  end
```
Mamy implementację metody w `app/models/book.rb`, więc możemy z tego skorzystać. Musimy tylko dodać odniesienie do `book`, przy odwołaniu do metody `can_reserve?` oraz kolekcji powiązanych obiektów.
Możemy też poprawić nazwę metody `can_reserve?`, żeby była bardziej czytelna ;)
```ruby
class ReservationsHandler
   def initialize(user, book)
    @user = user
    @book = book
  end

  def reserve
    return "Book is not available for reservation" unless book.can_be_reserved?(user)
    book.reservations.create(user: user, status: 'RESERVED')
  end

  private
  attr_reader :user, :book
end
```
Możemy teraz usunąć te metody z modelu, co sprawi, że będzie tam mniej niepotrzebnych rzeczy.

Następnie zabieramy się za metodę `cancel_reservation`. Metoda ta też się znajduje w modelu, co już wiemy, że nie jest odpowiednim miejscem na trzymanie logiki. Mamy już klasę `ReservationsHandler`, i tam umieścimy też logikę do skasowania rezerwacji.

Z `app/models/book.rb` przenosimy metodę `cancel_reservation`. Mamy w klasie `ReservationsHandler`już obiekt `user`'a, więc nie musimy przekazywać tego do metody. Ważne tylko pamiętać, że nie jesteśmy już w ramach `book.rb`, więc trzeba dodać referencję do obiektu.
```ruby
  def cancel_reservation
    book.reservations.where(user: user, status: 'RESERVED').order(created_at: :asc).first.update_attributes(status: 'CANCELED')
  end
```
## Użycie ReservationHandler
W `reservation_controller` teraz możemy uzyć naszego serwisu.
Metoda reserve w controller będzie zawierać jedynie wywołanie logiki z naszego service.
```ruby
  def reserve
    ReservationHandler.new(current_user, book).reserve
    redirect_to(book_path(book.id))
  end
```

Będziemy chcieli użyć tego serwisu w różnych metodach kontrolera, więc można wydzielić tworzenie obiektu do metody prywatnej
```ruby
  def reservation_handler
    @reservation_handler ||= ::ReservationsHandler.new(current_user, book)
  end
```


W podobny sposób proponuję przenieść też pozostałe publiczne metody związane z logiką rezerwacji (`take` i `give_back`), żeby trochę odchudzić model :)
***

Powodzenia !
