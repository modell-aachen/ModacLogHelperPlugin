import LogDecoder from '../components/LogDecoder.vue';
import translationsEn from '../translations/decoder_en.json';
import translationsDe from '../translations/decoder_de.json';


jQuery(function($) {
    Vue.component(LogDecoder.name, LogDecoder);
    Vue.addTranslation('en', 'ModacLogHelperPlugin', translationsEn);
    Vue.addTranslation('de', 'ModacLogHelperPlugin', translationsDe);

    $('.ModacLogHelperPlugin.vue-logdecoder').each(function() {
        let $this = $(this);

        let $component = $('<vue-log-decoder></vue-log-decoder>');
        $this.replaceWith($component);
        $component.wrap('<div class="flatskin-wrapped"></div>');
        Vue.instantiateEach( $component, {} );
    });
});


