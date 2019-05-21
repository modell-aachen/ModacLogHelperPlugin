import LogExporter from '../components/LogExporter';
import translationsEn from '../translations/exporter_en.json';
import translationsDe from '../translations/exporter_de.json';

jQuery(function($) {
    Vue.component(LogExporter.name, LogExporter);
    Vue.addTranslation('en', 'ModacLogHelperPlugin', translationsEn);
    Vue.addTranslation('de', 'ModacLogHelperPlugin', translationsDe);

    function sanitize(text) {
        let span = $('<span></span>');
        span.text(text);
        return span.html();
    }

    $('.ModacLogHelperPlugin.vue-logexporter').each(function() {
        let $this = $(this);

        let text = $this.data('text') || '';
        text = sanitize(text);

        let $component = $(`<vue-log-exporter>${text}</vue-log-exporter>`);
        $this.replaceWith($component);
        Vue.instantiateEach( $component, {} );
    });
});

