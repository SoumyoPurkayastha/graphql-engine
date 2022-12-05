{-# OPTIONS_GHC -Wno-deprecations #-}

-- | GENERATED BY 'server/tests-py/PortToHaskell.py'.
-- Please avoid editing this file manually.
module Test.PortedFromPytest.TestGraphQLQueryBasicCitus (spec) where

import Data.Aeson qualified as Yaml
import Data.List.NonEmpty qualified as NE
import Harness.GraphqlEngine qualified as GraphqlEngine
import Harness.PytestPortedCompat (compatSetup)
import Harness.Quoter.Graphql (graphql)
import Harness.Quoter.Yaml
import Harness.Test.Fixture qualified as Fixture
import Harness.TestEnvironment (GlobalTestEnvironment, TestEnvironment (..))
import Harness.Yaml (shouldReturnYaml)
import Hasura.Prelude
import Test.Hspec (SpecWith, describe, it)

-- original file: queries/graphql_query/citus/schema_setup_citus.yaml
schema_setup_Citus :: Yaml.Value
schema_setup_Citus =
  [interpolateYaml|
    type: bulk
    args:


    - type: citus_run_sql
      args:
        source: citus
        sql: |
          CREATE TABLE author (
              id serial PRIMARY KEY,
              name text UNIQUE,
              "createdAt" timestamp
          );

          CREATE TABLE article (
              id serial PRIMARY KEY,
              title text,
              content text,
              author_id integer REFERENCES author (id),
              is_published boolean,
              published_on timestamp
          );

          INSERT INTO author (name, "createdAt")
              VALUES ('Author 1', '2017-09-21T09:39:44'), ('Author 2', '2017-09-21T09:50:44');

          INSERT INTO article (title, content, author_id, is_published)
              VALUES ('Article 1', 'Sample article content 1', 1, FALSE), ('Article 2', 'Sample article content 2', 1, TRUE), ('Article 3', 'Sample article content 3', 2, TRUE);

          create table country (
            id serial primary key,
            name text not null
          );
          select create_reference_table('country');
          insert into country ("name") values ('India');

          create table state (
            id serial primary key,
            country_id integer references country(id),
            name text NOT NULL
          );

          select create_reference_table('state');
          insert into state ("country_id", "name")
          values (1, 'Karnataka'), (1, 'Andhra Pradesh'), (1, 'Orissa'), (1, 'Tamilnadu');

          create table disaster (
            id serial,
            country_id integer references country(id),
            name text not null,
            primary key (id, country_id)
          );
          select create_distributed_table('disaster', 'country_id');
          insert into disaster ("country_id", "name")
          values (1, 'cyclone_amphan'),
                 (1, 'cyclone_nisarga');

          create table disaster_affected_state (
            id serial,
            country_id integer references country(id),
            disaster_id integer,
            state_id integer references state(id),
            primary key (id, country_id)
          );
          select create_distributed_table('disaster_affected_state', 'country_id');

          create function search_disasters_sql(search text)
          returns setof disaster as $$
          begin
              return query select *
              from disaster
              where
                name ilike ('%' || search || '%');
          end;
          $$ language plpgsql stable;

          create function search_disasters_plpgsql(search text)
          returns setof disaster as $$
          begin
              return query select *
              from disaster
              where
                name ilike ('%' || search || '%');
          end;
          $$ language plpgsql stable;

    # run separately to foreign key constraint to avoid 'multiple utility event' error
    - type: citus_run_sql
      args:
        source: citus
        sql: |
          alter table disaster_affected_state add constraint disaster_fkey foreign key (country_id,       disaster_id) references disaster(country_id, id);

    - type: citus_run_sql
      args:
        source: citus
        sql: |
          insert into disaster_affected_state ("country_id", "disaster_id", "state_id")
            values (1, 1, 2), (1, 1, 3), (1, 2, 2), (1, 2, 3), (1, 2, 4);

  |]

-- original file: queries/graphql_query/citus/setup_citus.yaml
setup_metadata_Citus :: Yaml.Value
setup_metadata_Citus =
  [interpolateYaml|
    type: bulk
    args:

    #Author table
    - type: citus_track_table
      args:
        source: citus
        table:
          name: author

    #Article table
    - type: citus_track_table
      args:
        source: citus
        table:
          name: article

    #Object relationship
    - type: citus_create_object_relationship
      args:
        source: citus
        table: article
        name: author
        using:
          foreign_key_constraint_on: author_id

    #Array relationship
    - type: citus_create_array_relationship
      args:
        source: citus
        table: author
        name: articles
        using:
          foreign_key_constraint_on:
            table: article
            column: author_id

    #country table
    - type: citus_track_table
      args:
        source: citus
        table:
          name: country

    #state table
    - type: citus_track_table
      args:
        source: citus
        table:
          name: state

    #disaster table
    - type: citus_track_table
      args:
        source: citus
        table:
          name: disaster

    #disaster_affected_state table
    - type: citus_track_table
      args:
        source: citus
        table:
          name: disaster_affected_state


    # #using metadata from
    # #https://github.com/hasura/graphql-engine-mono/blob/vamshi/rfc/citus-support/rfcs/citus-support.md
    - type: citus_create_array_relationship
      args:
        source: citus
        table: country
        name: states
        using:
          foreign_key_constraint_on:
            table: state
            column: country_id

    - type: citus_create_array_relationship
      args:
        source: citus
        table: country
        name: disasters
        using:
          manual_configuration:
            remote_table: disaster
            column_mapping:
              id: country_id

    - type: citus_create_object_relationship
      args:
        source: citus
        table: state
        name: country
        using:
          foreign_key_constraint_on: country_id

    - type: citus_create_object_relationship
      args:
        source: citus
        table: disaster
        name: country
        using:
          manual_configuration:
            remote_table: country
            column_mapping:
              country_id: id

    - type: citus_create_array_relationship
      args:
        source: citus
        table: disaster
        name: affected_states
        using:
          manual_configuration:
            remote_table: disaster_affected_state
            column_mapping:
              id: disaster_id
              country_id: country_id

    - type: citus_create_object_relationship
      args:
        source: citus
        table: disaster_affected_state
        name: state
        using:
          manual_configuration:
            remote_table: state
            column_mapping:
              state_id: id

    - type: citus_create_object_relationship
      args:
        source: citus
        table: disaster_affected_state
        name: disaster
        using:
          manual_configuration:
            remote_table: disaster
            column_mapping:
              disaster_id: id
              country_id: country_id

    #search_disasters_sql function
    - type: citus_track_function
      args:
        source: citus
        function:
          name: search_disasters_sql

    #search_disasters_plpgsql function
    - type: citus_track_function
      args:
        source: citus
        function:
          name: search_disasters_plpgsql

  |]

fixture_Citus :: Fixture.Fixture ()
fixture_Citus =
  (Fixture.fixture $ Fixture.Backend Fixture.Citus)
    { Fixture.setupTeardown = \(testEnvironment, _) ->
        [ Fixture.SetupAction
            { Fixture.setupAction = do
                compatSetup testEnvironment Fixture.Citus
                void $ GraphqlEngine.postV2Query 200 testEnvironment schema_setup_Citus
                GraphqlEngine.postMetadata_ testEnvironment setup_metadata_Citus,
              Fixture.teardownAction = \_ -> return ()
            }
        ]
    }

spec :: SpecWith GlobalTestEnvironment
spec = Fixture.runSingleSetup (NE.fromList [fixture_Citus]) tests

tests :: Fixture.Options -> SpecWith TestEnvironment
tests opts = do
  let shouldBe :: IO Yaml.Value -> Yaml.Value -> IO ()
      shouldBe = shouldReturnYaml opts

  describe "test_nested_select_with_foreign_key_alter" do
    -- from: queries/graphql_query/citus/nested_select_with_foreign_key_alter_citus.yaml [0]
    it "Alter foreign key constraint on article table" \testEnvironment -> do
      void $
        GraphqlEngine.postV2Query
          200
          testEnvironment
          [interpolateYaml|
         type: citus_run_sql
         args:
           source: citus
           sql: |
             ALTER TABLE article DROP CONSTRAINT article_author_id_fkey,
               ADD CONSTRAINT article_author_id_fkey FOREIGN KEY (author_id) REFERENCES author(id);


       |]

    -- from: queries/graphql_query/citus/nested_select_with_foreign_key_alter_citus.yaml [1]
    it "Nested select on article" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              data:
                article:
                - id: 1
                  title: Article 1
                  content: Sample article content 1
                  author:
                    id: 1
                    name: Author 1
                - id: 2
                  title: Article 2
                  content: Sample article content 2
                  author:
                    id: 1
                    name: Author 1
                - id: 3
                  title: Article 3
                  content: Sample article content 3
                  author:
                    id: 2
                    name: Author 2

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query {
                  article {
                    id
                    title
                    content
                    author {
                      id
                      name
                    }
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_relationships_distributed.yaml [0]
    it "A distributed table can have foreign keys if it is referencing another colocated hash distributed table. Array relationship" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              data:
                disaster:
                - name: cyclone_amphan
                  affected_states:
                  - state:
                      name: Andhra Pradesh
                  - state:
                      name: Orissa
                - name: cyclone_nisarga
                  affected_states:
                  - state:
                      name: Andhra Pradesh
                  - state:
                      name: Orissa
                  - state:
                      name: Tamilnadu

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query distributed_to_distributed_array {
                  disaster {
                    name
                    affected_states {
                      state {
                        name
                      }
                    }
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_relationships_distributed.yaml [1]
    it "A distributed table can have foreign keys if it is referencing another colocated hash distributed table. Object relationship" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              data:
                disaster_affected_state:
                - id: 1
                  disaster:
                    name: cyclone_amphan
                - id: 2
                  disaster:
                    name: cyclone_amphan
                - id: 3
                  disaster:
                    name: cyclone_nisarga
                - id: 4
                  disaster:
                    name: cyclone_nisarga
                - id: 5
                  disaster:
                    name: cyclone_nisarga

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query distributed_to_distributed_object {
                  disaster_affected_state {
                    id
                    disaster {
                      name
                    }
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_relationships_distributed.yaml [2]
    it "A distributed table can have foreign keys if it is referencing a reference table" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              data:
                disaster:
                - name: cyclone_amphan
                  country:
                    name: India
                - name: cyclone_nisarga
                  country:
                    name: India

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query distributed_to_reference_object {
                  disaster {
                    name
                    country {
                      name
                    }
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_relationships_reference.yaml [0]
    it "Reference tables and local tables can only have foreign keys to reference tables and local tables. Array relationship" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              data:
                country:
                - name: India
                  states:
                  - name: Karnataka
                  - name: Andhra Pradesh
                  - name: Orissa
                  - name: Tamilnadu

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query reference_to_reference_array {
                  country {
                    name
                    states {
                      name
                    }
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_relationships_reference.yaml [1]
    it "Reference tables and local tables can only have foreign keys to reference tables and local tables. Object relationship" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              data:
                state:
                - name: Karnataka
                  country:
                    name: India
                - name: Andhra Pradesh
                  country:
                    name: India
                - name: Orissa
                  country:
                    name: India
                - name: Tamilnadu
                  country:
                    name: India

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query reference_to_reference_object {
                  state {
                    name
                    country {
                      name
                    }
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_relationships_reference.yaml [2]
    it "Reference tables and local tables cannot have foreign keys references to distributed tables" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              errors:
              - extensions:
                  code: unexpected
                  internal:
                    arguments:
                    - (Oid 114,Just ("{\"x-hasura-role\":\"admin\"}",Binary))
                    error:
                      description: There exist a reference table in the outer part of the outer
                        join
                      exec_status: FatalError
                      hint:
                      message: cannot pushdown the subquery
                      status_code: 0A000
                    prepared: true
                    statement: "SELECT  coalesce(json_agg(\"root\" ), '[]' ) AS \"root\" FROM  (SELECT\
                      \  json_build_object('name', \"_root.base\".\"name\", 'disasters', \"_root.ar.root.disasters\"\
                      .\"disasters\" ) AS \"root\" FROM  (SELECT  *  FROM \"public\".\"country\"\
                      \  WHERE ('true')     ) AS \"_root.base\" LEFT OUTER JOIN LATERAL (SELECT\
                      \  coalesce(json_agg(\"disasters\" ), '[]' ) AS \"disasters\" FROM  (SELECT\
                      \  json_build_object('name', \"_root.ar.root.disasters.base\".\"name\" ) AS\
                      \ \"disasters\" FROM  (SELECT  *  FROM \"public\".\"disaster\"  WHERE ((\"\
                      _root.base\".\"id\") = (\"country_id\"))     ) AS \"_root.ar.root.disasters.base\"\
                      \      ) AS \"_root.ar.root.disasters\"      ) AS \"_root.ar.root.disasters\"\
                      \ ON ('true')      ) AS \"_root\"      "
                  path: $
                message: database query error

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query reference_to_distributed_array {
                  country {
                    name
                    disasters {
                      name
                    }
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_functions.yaml [0]
    it "Querying a tracked SQL function will succeed" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              data:
                search_disasters_sql:
                - name: cyclone_nisarga

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query function {
                  search_disasters_sql(args: {search: "sarga"}) {
                    name
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_functions.yaml [1]
    it "Querying a tracked PL/PGSQL function will succeed" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              data:
                search_disasters_plpgsql:
                - name: cyclone_nisarga

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query function {
                  search_disasters_plpgsql(args: {search: "sarga"}) {
                    name
                  }
                }

              |]

      actual `shouldBe` expected

    -- from: queries/graphql_query/citus/select_query_disaster_functions.yaml [2]
    it "However, trying to use a relationship will result in an error" \testEnvironment -> do
      let expected :: Yaml.Value
          expected =
            [interpolateYaml|
              errors:
              - extensions:
                  code: unexpected
                  internal:
                    arguments:
                    - (Oid 114,Just ("{\"x-hasura-role\":\"admin\"}",Binary))
                    - (Oid 25,Just ("sarga",Binary))
                    error:
                      description: Complex subqueries, CTEs and local tables cannot be in the outer
                        part of an outer join with a distributed table
                      exec_status: FatalError
                      hint:
                      message: cannot pushdown the subquery
                      status_code: 0A000
                    prepared: true
                    statement: "SELECT  coalesce(json_agg(\"root\" ), '[]' ) AS \"root\" FROM  (SELECT\
                      \  json_build_object('name', \"_root.base\".\"name\", 'affected_states', \"\
                      _root.ar.root.affected_states\".\"affected_states\" ) AS \"root\" FROM  (SELECT\
                      \  *  FROM \"public\".\"search_disasters_plpgsql\"(($2)::text) AS \"_search_disasters_plpgsql\"\
                      \ WHERE ('true')     ) AS \"_root.base\" LEFT OUTER JOIN LATERAL (SELECT \
                      \ coalesce(json_agg(\"affected_states\" ), '[]' ) AS \"affected_states\" FROM\
                      \  (SELECT  json_build_object('state_id', \"_root.ar.root.affected_states.base\"\
                      .\"state_id\" ) AS \"affected_states\" FROM  (SELECT  *  FROM \"public\".\"\
                      disaster_affected_state\"  WHERE (((\"_root.base\".\"id\") = (\"disaster_id\"\
                      )) AND ((\"_root.base\".\"country_id\") = (\"country_id\")))     ) AS \"_root.ar.root.affected_states.base\"\
                      \      ) AS \"_root.ar.root.affected_states\"      ) AS \"_root.ar.root.affected_states\"\
                      \ ON ('true')      ) AS \"_root\"      "
                  path: $
                message: database query error

            |]

          actual :: IO Yaml.Value
          actual =
            GraphqlEngine.postGraphql
              testEnvironment
              [graphql|
                query function {
                  search_disasters_plpgsql(args: {search: "sarga"}) {
                    name
                    affected_states {
                      state_id
                    }
                  }
                }

              |]

      actual `shouldBe` expected
