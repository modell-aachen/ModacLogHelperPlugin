<template>
    <div class="LogDecoder grid-x">
        <div class="cell large-8 medium-12">
            <vue-header>
                {{ $t('logs_decoder_heading') }}
            </vue-header>
            <vue-text-block>
                {{ $t('logs_decoder_explain') }}
            </vue-text-block>
            <vue-header level="3">
                {{ $t('raw_or_file') }}
            </vue-header>
            <vue-input-text
                v-model="base64"
                :show-error="parseError"
                name="base64" />
            <input
                ref="fileInput"
                :disabled="!isFileReaderSupported"
                type="file"
                acccept=".qlog"
                name="file"
                @change="handleFileChange">
            <em
                v-if="!isFileReaderSupported">
                {{ $t('files_not_supported') }}
            </em>
            <vue-header level="3">
                {{ $t('user_data') }}
            </vue-header>
            <vue-input-text
                v-model="user"
                :label="$t('log_user')"
                is-readonly />
            <vue-input-text
                v-model="key"
                :label="$t('password')"
                is-password />
            <vue-spacer factor="2" />
            <vue-button
                :is-disabled="!canSubmit"
                :title="$t('show_logs')"
                type="primary"
                @click.native="decrypt" />
            <vue-text-block
                v-if="decryptError">
                {{ $t('decrypt_error') }}
            </vue-text-block>
        </div>

        <div class="cell large-12">
            <div
                v-if="logs">
                <div>
                    <vue-header3> Server time </vue-header3>
                    <pre>{{ $moment(servertime * 1000).format() }}</pre>
                    <vue-header3> Logs start </vue-header3>
                    <pre>{{ $moment(logsStart * 1000).format() }}</pre>
                    <vue-header3> Logs end </vue-header3>
                    <pre>{{ $moment(logsEnd * 1000).format() }}</pre>
                </div>
                <div
                    v-for="(logType) in logTypes"
                    :key="logType">
                    <vue-log-display
                        :log-type="logType"
                        :logs="logs[logType]" />
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import VueLogDisplay from './LogDisplay';

export default {
    name: 'VueLogDecoder',
    i18nextNamespace: 'ModacLogHelperPlugin',
    components: {
        VueLogDisplay,
    },
    props: {
    },
    data: function() {
        return {
            base64: '',
            user: '',
            key: '',
            data: null,
            logs: null,
            parseError: false,
            decryptError: false,
            servertime: 0,
            logsStart: 0,
            logsEnd: 0,
        };
    },
    computed: {
        isFileReaderSupported() {
            return window.File && window.FileReader && window.FileList && window.Blob;
        },
        canSubmit() {
            return (this.key.length && this.base64.length && !this.parseError) ? true : false;
        },
        logTypes() {
            return Object.keys(this.logs || {});
        },
    },
    watch: {
        base64() {
            let base64 = this.base64.trim();
            if(base64.length === 0) {
                this.parseError = false;
                return;
            }

            let split = this.userEndPos(base64);
            let user = base64.substr(0, split);
            let data = base64.substr(split);

            if(!(user && data)) {
                window.console.log('Could not separate user and data');
                this.parseError = true;
                return;
            }

            try {
                user = atob(user);
            } catch(e) {
                window.console.log('Could not parse user', e);
                this.parseError = true;
                return;
            }

            this.user = user;
            this.data = data;
            this.parseError = false;
        },
    },
    methods: {
        userEndPos(base64) {
            let split = 0;
            [' ', '\n', '\r'].forEach(character => {
                let index = base64.indexOf(character);
                if(index >= 0 && (split === 0 || split > index)) {
                    split = index;
                }
            });
            return split;
        },
        decrypt() {
            if(!this.canSubmit) {
                return;
            }
            this.$ajax({
                url: this.$foswiki.getScriptUrl('rest', 'ModacLogHelperPlugin', 'decrypt'),
                method: 'POST',
                dataType: 'json',
                data: {
                    key: this.key,
                    data: this.data,
                },
            }).done(response => {
                this.logs = response.logs;
                this.servertime = response.servertime;
                this.logsStart = response.logsstart;
                this.logsEnd = response.logsend;
                this.decryptError = false;
            }).fail(error => {
                this.decryptError = true;
                window.console.log('error while decrypting', error);
            });
        },
        handleFileChange() {
            let files = this.$refs.fileInput.files;
            if(files.length) {
                let reader = new FileReader();
                reader.onload = event => {
                    this.base64 = event.target.result;
                };
                reader.readAsText(files[0]);
            }
        },
    },
};
</script>

<style lang="scss">
</style>


