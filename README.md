# StateRouter (under development)
### Theory
* In classic router you map url to some route.
* In state router you map some portion of url to state.
* You don't work with routes. You work with states.
* State describes your current application state, e.g. if user is authorized or if user is filtering products.

# Describing a state
### Describing a state is pretty easy
```coffee
state 'profile',
  path: 'users/:id'
  controller: 'UserProfile'
```
### Specifying pattern instead of path
```coffee
state 'profile',
  # Named regex group by XRegExp 
  pattern: 'users/(?<id>\d+))'
  controller: 'UserProfile'
  # If you want to reassemble states's route from params you must describe route assembler. This is not needed if your state's route is based on path.  
  assembler: (params) -> "users/#{params.id}"
```
### Abstract states
If you don't want to allow enter state you can mark it as abstract.
```coffee
state 'app',
  pattern: '(?<locale>en|fr)'
  controller: 'Application'
  abstract: yes
```
### Nesting states
```coffee
state 'app',
  pattern: '(?<locale>en|fr)'
  controller: 'Application'
, ->

  state 'index',
    path: ''
    controller: 'Index'
    
  state 'profile',
    pattern: 'users/:id'
    controller: 'UserProfile'
```
This will create routes:
* (en|fr)
* (en|fr)/users/:id