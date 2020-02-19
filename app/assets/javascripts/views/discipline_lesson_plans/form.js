$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#discipline_lesson_plan_lesson_plan_attributes_classroom_id');
  var $discipline = $('#discipline_lesson_plan_discipline_id');
  var $classes = $('#discipline_lesson_plan_classes');
  var $classes_div = $('.discipline_lesson_plan_classes');
  var $lesson_plan_attachment = $('#lesson_plan_attachment');
  const copyTeachingPlanLink = document.getElementById('copy-from-teaching-plan-link');
  const startAtInput = document.getElementById('discipline_lesson_plan_lesson_plan_attributes_start_at');
  const endAtInput = document.getElementById('discipline_lesson_plan_lesson_plan_attributes_end_at');

  $(".lesson_plan_attachment").on('change', onChangeFileElement);

  function onChangeFileElement(){
    // escopado para permitir arquivos menores que 3MB(3145728 bytes)
    if (this.files[0].size > 3145728) {
      $(this).closest(".control-group").find('span').remove();
      $(this).closest(".control-group").addClass("error");
      $(this).after('<span class="help-inline">tamanho máximo por arquivo: 3 MB</span>');
      $(this).val("");
    }else {
      $(this).closest(".control-group").removeClass("error");
      $(this).closest(".control-group").find('span').remove();
    }
  }

  $('#discipline_lesson_plan').on('cocoon:after-insert', function(e, item) {
    $(item).find('input.file').on('change', onChangeFileElement);
  });

  function classroomChangeHandler() {
    var classroom_id = $classroom.select2('val');

    $discipline.select2('val', '');
    $discipline.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      fetchDisciplines(classroom_id);
      fetchExamRule(classroom_id);
    } else {
      $classes_div.hide();
      $classes.select2('val', '');
    }
  };

  $classroom.on('change', classroomChangeHandler);

  function fetchDisciplines(classroom_id) {
    $.ajax({
      url: Routes.disciplines_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handleFetchDisciplinesSuccess,
      error: handleFetchDisciplinesError
    });
  };

  function handleFetchDisciplinesSuccess(disciplines) {
    var selectedDisciplines = _.map(disciplines, function(discipline) {
      return { id: discipline['id'], text: discipline['description'] };
    });

    $discipline.select2({ data: selectedDisciplines });
  };

  function handleFetchDisciplinesError() {
    flashMessages.error('Ocorreu um erro ao buscar as disciplinas da turma selecionada.');
  };

  function fetchExamRule(classroom_id) {
    $.ajax({
      url: Routes.exam_rules_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
      success: handleFetchExamRuleSuccess,
      error: handleFetchExamRuleError
    });
  };

  function handleFetchExamRuleSuccess(data) {
    var examRule = data.exam_rule
    if (!$.isEmptyObject(examRule) && examRule.frequency_type !== '1') {
      $classes_div.show();
    } else {
      $classes_div.hide();
      $classes.select2('val', '');
    }
  };

  function handleFetchExamRuleError() {
    flashMessages.error('Ocorreu um erro ao buscar a regra de avaliação da turma selecionada.');
  };

  $('#discipline_lesson_plan_lesson_plan_attributes_contents_tags').on('change', function(e){
    if(e.val.length){
      var content_description = e.val.join(", ");
      if(content_description.trim().length &&
          !$('input[type=checkbox][data-content_description="'+content_description+'"]').length){

        var html = JST['templates/layouts/contents_list_manual_item']({
          description: content_description,
          model_name: 'discipline_lesson_plan',
          submodel_name: 'lesson_plan'
        });

        $('#contents-list').append(html);
        $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
      }else{
        var content_input = $('input[type=checkbox][data-content_description="'+content_description+'"]');
        content_input.closest('li').show();
        content_input.prop('checked', true).trigger('change');
      }

      $('.discipline_lesson_plan_lesson_plan_contents_tags .select2-input').val("");
    }
    $(this).select2('val', '');
  });

  const addElement = (description) => {
    if(!$('li.list-group-item.active input[type=checkbox][data-content_description="'+description+'"]').length) {
      const newLine = JST['templates/layouts/contents_list_manual_item']({
        description: description,
        model_name: window['content_list_model_name'],
        submodel_name: window['content_list_submodel_name']
      });

      $('#contents-list').append(newLine);
      $('.list-group.checked-list-box .list-group-item:not(.initialized)').each(initializeListEvents);
    }
  };

  const fillContents = (data) => {
    data.discipline_lesson_plans.forEach(content => addElement(content.description));
  }

  copyTeachingPlanLink.addEventListener('click', event => {
    event.preventDefault();

    if (!startAtInput.value || !endAtInput.value) {
      flashMessages.error('É necessário preenchimento das datas para realizar a cópia.');
      return false;
    }
    const url = Routes.teaching_plan_contents_discipline_lesson_plans_pt_br_path();
    const params = {
      start_date: startAtInput.value,
      end_date: endAtInput.value
    }

    $.getJSON(url, params)
    .done(fillContents);


    return false;
  });
});
