<template>
  <v-container>
    <v-layout align-center justify-center>
      <v-flex xs12 lg8 xl6>
        <h1>Welcome to the Critical Linkages Scenario Builder!</h1>
        <v-layout align-center justify-center>
          <v-container grid-list-xl>
            <v-layout column>
              <v-flex>
                <v-card>
                  <v-toolbar dark color="blue">
                    <v-toolbar-title>Create New Project</v-toolbar-title>
                  </v-toolbar>
                  <v-card-text>Create a new project.</v-card-text>
                  <v-card-actions>
                    <v-btn flat to="/project/new">
                      Create Project <v-icon>arrow_forward</v-icon>
                    </v-btn>
                  </v-card-actions>
                </v-card>
              </v-flex>
              <v-flex>
                <v-card>
                  <v-toolbar dark color="blue">
                    <v-toolbar-title>Load Existing Project</v-toolbar-title>
                  </v-toolbar>
                  <v-card-text>Load an existing project from text file.</v-card-text>
                  <v-card-actions>
                    <v-btn flat to="/project/load">
                      Load Project <v-icon>arrow_forward</v-icon>
                    </v-btn>
                  </v-card-actions>
                </v-card>
              </v-flex>
            </v-layout>
          </v-container>
        </v-layout>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<style scoped>
</style>
