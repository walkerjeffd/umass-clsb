<template>
  <v-container>
    <v-layout column>
      <h1>Welcome to the Critical Linkages Scenario Builder!</h1>
      <p class="pt-3">To get started:</p>
      <v-layout>
        <v-flex xs12 md6>
          <v-container grid-list-xl>
            <v-layout column>
              <v-flex xs12>
                <v-card>
                  <v-card-title class="blue headline white--text">
                    Create New Project
                  </v-card-title>
                  <v-card-text>Create a new project from scratch.</v-card-text>
                  <v-card-actions>
                    <v-btn flat to="/project/new">
                      Start Project <v-icon>arrow_forward</v-icon>
                    </v-btn>
                  </v-card-actions>
                </v-card>
              </v-flex>
              <v-flex xs12>
                <v-card>
                  <v-card-title class="blue headline white--text">
                    Load Existing Project
                  </v-card-title>
                  <v-card-text>Load an existing project from file.</v-card-text>
                  <v-card-actions>
                    <v-btn flat to="/project/load">
                      Load Project <v-icon>arrow_forward</v-icon>
                    </v-btn>
                  </v-card-actions>
                </v-card>
              </v-flex>
            </v-layout>
          </v-container>
        </v-flex>
      </v-layout>
    </v-layout>
  </v-container>
</template>

<style scoped>
</style>
