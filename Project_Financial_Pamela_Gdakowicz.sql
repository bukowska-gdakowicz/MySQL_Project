#Zadanie 1. Historia udzielanych kredytów
#Task 1. History of loans granted

#Napisz zapytanie, które przygotuje podsumowanie z udzielanych
#kredytów w następujących wymiarach:

#rok, kwartał, miesiąc,
#rok, kwartał,
#rok,
#sumarycznie.

#Jako wynik podsumowania wyświetl następujące informacje:

#sumaryczna kwota pożyczek,
#średnia kwota pożyczki,
#całkowita liczba udzielonych pożyczek.

#Write a query that prepares a summary of granted loans across the following
#dimensions:

#year, quarter, month
#year, quarter
#year
#overall total

#As the result of the summary, display the following information:

#total loan amount
#average loan amount
#total number of granted loans


select
extract(YEAR from date) as year,
extract(quarter from date) as quarter,
extract(month from date) as month,
sum(amount) as sum_amount,
avg(amount) as avg_amount,
count(amount) as number_of_loans
from financial1_127.loan
group by year, month, quarter with rollup
order by year,quarter,month desc;


#Zadanie 2. Status pożyczki
# Task 2. Loan status

#Na stronie bazy danych możemy znaleźć informację, że w bazie znajdują się
#w sumie 682 udzielone kredyty, z czego 606 zostało spłaconych, a 76 nie.
#Załóżmy, że nie posiadamy informacji o tym, który status odpowiada pożyczce
#spłaconej, a który nie. W takiej sytuacji musimy te informacje wywnioskować
# z danych.

#W tym celu napisz kwerendę, za pomocą której spróbujesz odpowiedzieć na pytanie,
#które statusy oznaczają pożyczki spłacone, a które oznaczają pożyczki niespłacone.

#On the database website, we can find information stating that there are a total
#of 682 granted loans in the database, of which 606 have been repaid and 76 have not.

#Let’s assume we do not have information about which status corresponds to a repaid
#loan and which one to an unpaid loan. In this case, we need to infer this from the
#data.

#To do this, write a query that attempts to determine which statuses correspond to
#repaid loans and which to unpaid loans.

#I'm checking if the number f records is correct, should be 682.
select
count(*)
from financial1_127.loan;

select
    status,
    count(*)
from financial1_127.loan
group by status
order by status;

#loans repaid:A,C:203(A)+403(C)=606
#loans outstanding:B,D:31(B)+45(D)=76.

#Zadanie 3. Analiza kont
#Task 3. Account Analysis

#Napisz kwerendę, która uszereguje konta według następujących kryteriów:

#liczba udzielonych pożyczek (malejąco),
#kwota udzielonych pożyczek (malejąco),
#średnia kwota pożyczki.
#Pod uwagę bierzemy tylko spłacone pożyczki.

#Write a query that ranks accounts based on the following criteria:
#number of granted loans (in descending order)
#total amount of granted loans (in descending order)
#average loan amount
#Only repaid loans should be taken into account.

with account_analysis as(
select
account_id,
count(loan_id) as number_of_loans,
sum(amount) as sum_amount,
avg(amount) as avg_amount
from financial1_127.loan
where status in ('A','C')
group by account_id)
select
    *,
    row_number() over(order by number_of_loans desc) as rank_number_of_loans,
    row_number() over (order by sum_amount desc) as rank_sum_amount
from account_analysis;

#Zadanie 4. Spłacone pożyczki
# Task 4. Loans Paid

#Sprawdź, saldo pożyczek spłaconych w podziale na płeć klienta.
#Dodatkowo w wybrany przez siebie sposób sprawdź, czy kwerenda jest poprawna.

#Check the balance of repaid loans broken down by the customer's gender.
#Additionally, verify in a way of your choice whether the query is correct.


use financial1_127;
create temporary table tmp_results as
select
c.gender as plec,
sum(l.amount) as amount
from financial1_127.loan l
join financial1_127.account a on (l.account_id=a.account_id)
join financial1_127.disp d on (a.account_id=d.account_id)
join financial1_127.client c on(d.client_id=c.client_id)
where l.status in('A','C') and d.type='owner'
group by c.gender;

select
    * from tmp_results;

with account_analysis as (
    select sum(amount) as amount
    from financial1_127.loan as l where l.status in('A','C')
)select (select sum(amount) from tmp_results)-(select amount from account_analysis) as difference;

#Zadanie 5. Analiza klienta część 1.
#Task 5. Customer analysis part 1.

#Modyfikując zapytania z zadania dot. spłaconych pożyczek, odpowiedz na poniższe pytania:

#kto posiada więcej spłaconych pożyczek – kobiety czy mężczyźni?
#jaki jest średni wiek kredytobiorcy w zależności od płci?
#Podpowiedzi:
#Zapisz wynik napisanej wcześniej, a następnie zmodyfikowanej kwerendy np. do tabeli tymczasowej i na niej przeprowadź analizę.
#Wiek możesz policzyć jako różnicę 2021 - rok urodzenia kredytobiorcy.

#By modifying the queries from the task related to repaid loans, answer the following questions:

#Who has more repaid loans – women or men?
#What is the average age of the borrower depending on gender?

#Hints:

#Save the result of the previously written (and then modified) query to a
#temporary table and perform the analysis on it.
#You can calculate the age as the difference between 2021 and the borrower's
#year of birth.

select
    * from tmp_results;

#kto posiada więcej spłaconych pożyczek – kobiety czy mężczyźni?
#jaki jest średni wiek kredytobiorcy w zależności od płci?

create temporary table tmp_results_corrected as
select
c.gender as plec,
2021-extract(year from c.birth_date) as age,
sum(l.amount) as amount,
count(l.amount) as number_of_loans
from financial1_127.loan l
join financial1_127.account a on (l.account_id=a.account_id)
join financial1_127.disp d on (a.account_id=d.account_id)
join financial1_127.client c on(d.client_id=c.client_id)
where l.status in('A','C') and d.type='owner'
group by c.gender, 2;

#I'm checking if its correct (the total number of paid loans)

select
    sum(number_of_loans) as paid_loans
from tmp_results_corrected;

#Checked and corrected, the number is 606.

select
    plec,
    sum(number_of_loans) sum_of_loans
from tmp_results_corrected
group by plec;

#plec= gender; the answer for the first question is,'Female have more paid loans'

select
    plec,
    avg(age*number_of_loans)/sum(number_of_loans) as avg_age
from tmp_results_corrected
group by plec;


#Zadanie 6. Analiza klienta cz.2
#Task 6. Customer analysis part 2.

#Dokonaj analiz, które odpowiedzą na pytania:

#w którym rejonie jest najwięcej klientów,
#w którym rejonie zostało spłaconych najwięcej pożyczek ilościowo,
#w którym rejonie zostało spłaconych najwięcej pożyczek kwotowo.
#Jako klienta wybierz tylko właścicieli kont.

#Perform analyses that will answer the following questions:
#In which region are there the most clients?
#In which region has the highest number of loans been repaid (by quantity)?
#In which region has the highest total value of loans been repaid (by amount)?
#Only consider account holders as clients.

#In which region are there the most clients?

select
    district_id,
    count(client_id) as number_of_clients
from financial1_127.client
group by district_id
order by number_of_clients desc;

#answer: in district_id =1 there is the most clients.

#In which region has the highest number of loans been repaid (by quantity)?
#In which region has the highest total value of loans been repaid (by amount)?

create temporary table tmp_task6 as
select
d2.district_id,
count(l.amount) as number_of_loans,
sum(l.amount) as loans_amount
from financial1_127.loan l
join financial1_127.account a on (l.account_id=a.account_id)
join financial1_127.disp d on (a.account_id=d.account_id)
join financial1_127.client c on(d.client_id=c.client_id)
join financial1_127.district d2 on(c.district_id=d2.district_id)
where l.status in('A','C') and d.type='owner'
group by d2.district_id;

select * from tmp_task6;

#In which region has the highest number of loans been repaid (by quantity)?

select
    *
from tmp_task6
order by number_of_loans desc;

#result: district_id=1

#In which region has the highest total value of loans been repaid (by amount)?

select
    *
from tmp_task6
order by loans_amount desc;

#result: district_id=1

#Zadanie 7. Analiza klienta cz.3
#Task 7. Customer analysis part 3.

#Używając kwerendy otrzymanej w poprzednim zadaniu, dokonaj jej modyfikacji
#w taki sposób, aby wyznaczyć procentowy udział każdego regionu w całkowitej
# kwocie udzielonych pożyczek.
#Przykładowy wynik:

#district_id	customer_amount	loans_given_amount	loans_given_count	amount_share
#1	             73	               100	               2	          0.6666
#74	             17	                50	               5	          0.3333
#Innymi słowy, chodzi o wyznaczenie rozkładu udzielanych pożyczek ze względu na
#regiony.

#Using the query obtained in the previous task, modify it to calculate the
#percentage share of each region in the total amount of loans granted.
#Example result:
#district_id	customer_amount	loans_given_amount	loans_given_count	amount_share
#1	                  73	            100	                2	                0.6666
#74	                  17	            50	                5	                0.3333
#In other words, the goal is to determine the distribution of granted loans by region.

WITH cte AS(
    select
    d2.district_id,
    count(l.amount) as number_of_loans,
    sum(l.amount) as loans_amount
    from financial1_127.loan l
    join financial1_127.account a on (l.account_id=a.account_id)
    join financial1_127.disp d on (a.account_id=d.account_id)
    join financial1_127.client c on(d.client_id=c.client_id)
    join financial1_127.district d2 on(c.district_id=d2.district_id)
    where l.status in('A','C') and d.type='owner'
    group by d2.district_id
)
select *,
       loans_amount/sum(loans_amount) over() as percentage
from cte
order by percentage desc;


#Zadanie 8. Selekcja klientow cz.1
#Task 8. Clients selection part 1.


#Sprawdź, czy w bazie występują klienci spełniający poniższe warunki:
#saldo konta przekracza 1000,
#mają więcej niż pięć pożyczek,
#są urodzeni po 1990 r.
#Przy czym zakładamy, że saldo konta to kwota pożyczki - wpłaty.

#Check whether there are any customers in the database who meet the following conditions:
#The account balance exceeds 1000,
#They have more than five loans,
#They were born after 1990.
#Assume that the account balance is calculated as the loan amount minus the deposit amount.

select
    c.client_id,
    sum(amount-payments) as client_balance,
    count(l.loan_id) as number_of_loans
from financial1_127.loan l
join financial1_127.account a on l.account_id = a.account_id
join financial1_127.disp d on a.account_id = d.account_id
join financial1_127.client c on d.client_id = c.client_id
join financial1_127.district d2 on a.district_id = d2.district_id
where
d.type='owner'
AND EXTRACT(YEAR FROM c.birth_date) > 1990
group by c.client_id
having
    sum(amount-payments)>1000
and count(loan_id)>5;

#customers have at most 1 loan

#Zadanie 9. Wygasające karty
#Task 9. Expiring cards

#Napisz procedurę, która będzie odświeżać stworzoną przez Ciebie tabelę
#(możesz nazwać ją np. cards_at_expiration) zawierającą następujące kolumny:
#id klienta,
#id_karty,
#data wygaśnięcia – załóż, że karta może być aktywna przez 3 lata od wydania,
#adres klienta (wystarczy kolumna A3).
#Uwaga: W tabeli card zawarte są karty, które zostały wydane do końca 1998.

#Wyznaczenie daty wygaśnięcia karty
#Załóżmy, że mamy kartę wydaną 2020-01-01, data jej wygaśnięcia zgodnie z warunkami zadania
#to 2023-01-01. Ponieważ chcemy wysyłać nowe karty tydzień przed datą wygaśnięcia, wtedy wystarczy sprawdzić warunek 2023-01-01 - 7 dni = 2022-12-25 <= DATA <= 2023-01-01.

#Write a procedure that refreshes a table created by you
#(you can name it cards_at_expiration) containing the following columns:

#client ID,
#card ID,
#expiration date – assume that a card is valid for 3 years from the issue date,
#client address (only column A3 is needed).

#Note: The card table contains cards that were issued up to the end of 1998.

select
    c.client_id,
    card.card_id,
    DATE_ADD(card.issued, interval 3 year) as expiration_date,
    d2.A3 as client_address
from financial1_127.client c
join financial1_127.disp d on (c.client_id=d.client_id)
join financial1_127.card card on(d.disp_id=card.disp_id)
join financial1_127.district d2 on (c.district_id=d2.district_id);

#robimy sobie podzapytanie zeby dalej z niego wyfiltrować karty wygasajace:

with cte as
(select
    c.client_id,
    card.card_id,
    DATE_ADD(card.issued, interval 3 year) as expiration_date,
    d2.A3 as client_address
from financial1_127.client c
join financial1_127.disp d on (c.client_id=d.client_id)
join financial1_127.card card on(d.disp_id=card.disp_id)
join financial1_127.district d2 on (c.district_id=d2.district_id))
select
    *
from cte
WHERE '2000-01-01' BETWEEN DATE_ADD(expiration_date, INTERVAL -7 DAY) AND expiration_date;


CREATE TABLE financial1_127.cards_at_expiration
(
    client_id       int                      not null,
    card_id         int default 0            not null,
    expiration_date date                     null,
    A3              varchar(15) charset utf8 not null,
    generated_for_date date                     null
);

DELIMITER $$
DROP PROCEDURE IF EXISTS financial1_127.generate_cards_at_expiration_report;

CREATE PROCEDURE financial1_127.generate_cards_at_expiration_report(p_date DATE)
BEGIN
END;
DELIMITER ;

with cte as
(select
    c.client_id,
    card.card_id,
    DATE_ADD(card.issued, interval 3 year) as expiration_date,
    d2.A3 as client_address
from financial1_127.client c
join financial1_127.disp d on (c.client_id=d.client_id)
join financial1_127.card card on(d.disp_id=card.disp_id)
join financial1_127.district d2 on (c.district_id=d2.district_id))
select
    *
from cte
WHERE p_date BETWEEN DATE_ADD(expiration_date, INTERVAL -7 DAY) AND expiration_date;

DELIMITER $$
DROP PROCEDURE IF EXISTS financial1_127.generate_cards_at_expiration_report;
CREATE PROCEDURE financial1_127.generate_cards_at_expiration_report(p_date DATE)
BEGIN
    TRUNCATE TABLE financial1_127.cards_at_expiration;
    INSERT INTO financial1_127.cards_at_expiration
    with cte as
(select
    c.client_id,
    card.card_id,
    DATE_ADD(card.issued, interval 3 year) as expiration_date,
    d2.A3 as client_address
from financial1_127.client c
join financial1_127.disp d on (c.client_id=d.client_id)
join financial1_127.card card on(d.disp_id=card.disp_id)
join financial1_127.district d2 on (c.district_id=d2.district_id))
select
    *,
    p_date
from cte
WHERE p_date BETWEEN DATE_ADD(expiration_date, INTERVAL -7 DAY) AND expiration_date;
    END;
DELIMITER ;

CALL financial1_127.generate_cards_at_expiration_report('2001-01-01');
SELECT * FROM financial1_127.cards_at_expiration;