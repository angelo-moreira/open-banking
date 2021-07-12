# OpenBanking

## Overview

The main purpose of this software is to match ***transaction descriptions*** to known ***Merchants***, we will be using the word **Transaction** and **Merchant** across this document.

The main decisions I have concentrated on was:

- Write a program that will be more accurate overtime as the data grows
- Matching speed by using algorithms proven to be efficient based in previous research, the algorithm chosen is [trigrams](https://www.postgresql.org/docs/9.6/pgtrgm.html)
- Simulate an API by using `mix tasks` that would make reviewing existing transactions easier in order to not have much staff using it.

An example of a transaction would be "uber help.uber.com", this transaction should match to the "Uber" merchant.

## Requirements

For the bot to work we are going to need Docker, Docker Compose and Elixir v1.12 installed in the host machine.

I recommend installing and using Elixir with [asdf](https://github.com/asdf-vm/asdf) (a tool to manage multiple different programming languages in the host machine).

## start up the application

Run `docker-compose up database` to initialise the database.

Run `mix open_banking` to have a list of everything you can do within the application.

## Interacting with the program

We will be taking advantage of [Mix Tasks](https://hexdocs.pm/mix/1.12/Mix.Task.html) in order to provide some commands that can be executed in the terminal.

All the needed documentation and options will be presented in the terminal when running `mix open_banking` a list and description of all the tasks will be presented.

We can then have a look at all the flags by typing `mix help open_banking.task_name`

All the documentation around using the different tasks will be presented in the terminal, this document would be more of a high level overview of technical decisions instead of a detailed manual.

## Choosing a matching algorithm

After doing some research I opted to use the `trigram` algorithms, I think this would match better than other algorithms like `soundex` for the shape of data we will be working on, our data resembles a list of keywords, so I think by using `trigrams` we would be able to have better matches.

The **Trigram** algo will return a confidence level when matching a description against a **merchant**, the confidence level will be quite poor in the beggining because we are matching long string against short ones, however as we gather more data and the staff gives feedback regarding the discovered data the confidence level will sky rocket, I think in the begging we will need lots of staff members but we will eventually get to a point where only 1 or 2 staff will be required to train our application.

## Database

I have chosen Postgres because it's a widely used Database and for an initial development will be perfect, as we understand the problem better and the more load we have (initially we are planning for 1m transactions), we could potentially start looking at other technologies build by scale for this particular problem, Elastic Search could be one of them.

### Database Storage

The **trigram** algo would need to index a lot of data in order to be fast when doing comparison, we are trading off storage costs aginst speed of matching, I feel that is justified and quite a standard decision, storage is very cheap nowadays, I have not run a cost 
simulation to understand how much would this cost.

## Why Mix tasks instead of a build version

The target for testing would probably want to have a look at the source code, and probably change some tests around so I didn't see the need to produce a build, however if I would be running this in prod I would build the application and create a docker container to run it in a Kubernetes environment.

## Are you serioulsy adding credentials in the project?

I feel that it's not a big problem because the only creds are `dev` and `test` no `prod` credentials have been added, if this was a prod project I would be adding those as Env vars in a pipeline obviously.

# Things I could improve

There are lots of things that could be improved but I have decided not to do it at this stage, on top of my head the following stand out:

- Unique merchants and transactions, at the moment we can have duplicated merchants and transactions, that is quite bad but I feel like I overdone it as it is already.
- Provide a better API when searching for transaction, we could implement things like ordering, pagination and probably description keywords matching.
- Transactions relations, at the moment we save a transaction when it matches another one in the system and pull its merchant.

  However there are massive problems with this approach that I've decided to overlook because it would time too long to implement.

  What happens if **transaction 1** merchant is changed to a different merchant.

  We could be in a situation where **transaction 2** and **transaction 3** merchant will have been matched against **transaction 1** and now have an incorrect merchant, to solve this problem we would have to store what was the transaction we matched against and update all the other transactions when an update occurs.

- The **merchant API** quality is much worst than the **Transactions API** because I was running out of time so I cut down in tests and documentation.

- Mix tasks testing, there are no test against the mix tasks because I ran out of time, however you can see how that quality would look like when looking at the **Transaction** module
