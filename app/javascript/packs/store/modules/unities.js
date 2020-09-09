import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const unities = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false
  },
  mutations,
  getters,
  actions: {
    preLoad({commit, getters}) {
      commit('setOptions', window.state.available_unities)
      commit('setSelected', getters.getById(window.state.current_unity_id))
    },
    fetch({ dispatch, state, commit, rootState }) {
      commit('setSelected', null, { root: true })
      commit('setOptions', [], { root: true })
      commit('school_years/setSelected', null, { root: true })
      commit('school_years/setOptions', [], { root: true })
      commit('classrooms/setSelected', null, { root: true })
      commit('classrooms/setOptions', [], { root: true })
      commit('teachers/setSelected', null, { root: true })
      commit('teachers/setOptions', [], { root: true })
      commit('disciplines/setOptions', [], { root: true })
      commit('disciplines/setSelected', null, { root: true })

      const filters = { }

      if(rootState.unities.selected.id) {
        filters['by_id'] = rootState.unities.selected.id
      }

      const route = Routes.search_unities_pt_br_path({
        format: 'json',
        per: 9999999,
        filter: filters
      })

      axios.get(route)
        .then(response => {
          commit('setOptions', response.data.unities)

          if(response.data.unities.length === 1) {
            commit('setSelected', response.data.unities[0].id)

            dispatch('school_years/fetch', null, { root: true })
          }

        })
    }
  }
}

export default unities
