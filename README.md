# SensCritique Exporter

Script pour exporter votre collection de films depuis SensCritique vers une base de données locale *(SQLite par défaut)*.

<hr>

SensCritique fait miroiter une API depuis bientôt 10 ans, et toujours rien à l'horizon :
- [2021](https://senscritique-com.medium.com/cest-pr%C3%A9vu-mais-on-n-a-pas-encore-de-date-%C3%A0-donner-9ccfc68d1c60)
- [2019](https://senscritique.eu.helpdocs.com/suggestions/api-ouverte-a-tous)
- [2015](https://www.nextinpact.com/article/18915/96073-sens-critique-genese-aux-projets-a-venir)

En plus de ça, [l'ancien site](https://old.senscritique.com/) ferme le 30/10/2023, alors qu'il héberge le wiki qui permet d'éditer les oeuvres, qui n'a pas d'équivalent sur le nouveau site. *(le wiki inclut des données non-présentes sur le nouveau site, notamment l'identifiant IMDB pour les films)*

Du coup, script fait-maison pour exporter les films dans une base de données propre, pour éventuellement plus tard les importer sur Letterboxd [*(API publique disponible)*](https://api-docs.letterboxd.com/).

<hr>

### Installation

- Renommer le ficher `app/config/config.yaml.example` en `app/config/config.yaml`
	- Remplir les valeurs :
		- `username`
		- `SC_AUTH`
		- `SC_AUTH_ID`

- Installer les dépendances :
```bash
bundle install
```

- Exécuter le script :
```bash
ruby app/main.rb
```

<hr>

### Dépendances

- ActiveRecord *(Rails)*
- Nokogiri
- Faraday

<hr>

### Format des données

| id | title | sc_url_id | sc_url_name | imdb_id | director | country | rating | status | category | original_title | release_date | duration |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Bienvenue à Gattaca | 488559 | bienvenue_a_gattaca | tt0119177 | Andrew Niccol | Etats-Unis | 10 | 1 | Film | Gattaca | 1997-24-10 | 106 |