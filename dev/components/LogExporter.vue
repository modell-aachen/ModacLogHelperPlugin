<template>
    <span class="LogExporter">
        <span class="inline-block">
            <sidebar ref="sidebar">
                <sidebar-standard-layout>
                    <div
                        slot="content"
                        class="add-content cell">
                        <vue-header2>{{ $t('export_logs') }}</vue-header2>
                        <vue-text-block is-full-width>{{ $t('export_description') }}</vue-text-block>
                        <vue-spacer factor-vertical="3" />
                        <vue-datepicker
                            v-model="internalStartDate"
                            :label="$t('logs_start')" />
                        <vue-spacer factor-vertical="2" />
                        <vue-datepicker
                            v-model="internalEndDate"
                            :label="$t('logs_end')" />
                        <vue-spacer factor-vertical="3" />
                        <vue-check-item
                            v-model="useInfoLogs">
                            {{ $t('use_info_logs') }}
                        </vue-check-item>
                        <vue-check-item
                            v-model="asFile">
                            {{ $t('as_file') }}
                        </vue-check-item>
                        <vue-spacer factor-vertical="6" />
                        <vue-button
                            :title="$t('export_logs')"
                            type="primary"
                            @click.native="openDownloadDialog" />
                    </div>
                </sidebar-standard-layout>
            </sidebar>
        </span>
        <a
            href="#"
            @click="$refs.sidebar.show()">
            <slot>log export</slot>
        </a>
    </span>
</template>

<script>
export default {
    name: 'VueLogExporter',
    i18nextNamespace: 'ModacLogHelperPlugin',
    props: {
        startDate: {
            type: Date,
            default() {
                let date = new Date();
                date.setMonth(date.getMonth() - 1);
                date.setHours(0);
                date.setMinutes(0);
                date.setSeconds(0);
                return date;
            },
        },
        endDate: {
            type: Date,
            default() {
                let date = new Date();
                date.setHours(23);
                date.setMinutes(59);
                date.setSeconds(59);
                return date;
            },
        },
    },
    data() {
        return {
            internalStartDate: this.startDate,
            internalEndDate: this.endDate,
            useInfoLogs: false,
            asFile: true,
        };
    },
    watch: {
    },
    methods: {
        formatDate(date) {
            return `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
        },
        openDownloadDialog() {
            this.$ajax({
                url: this.$foswiki.getScriptUrl('rest', 'ModacLogHelperPlugin', 'loginfo'),
                method: 'POST',
                dataType: 'text',
                data: {
                    logsstart: this.internalStartDate,
                    logsend: this.internalEndDate,
                    useinfologs: this.useInfoLogs,
                },
            }).done(response => {
                if(this.asFile) {
                    let formattedStartDate = this.formatDate(this.internalStartDate);
                    let formattedEndDate = this.formatDate(this.internalEndDate);
                    let filename = `qwiki_logs_${formattedStartDate}_${formattedEndDate}.qlog`;
                    let blobData = new Blob(
                        [ response ],
                        {type: 'text/plain'}
                    );

                    if( navigator.appVersion.toString().indexOf('.NET') > 0) {
                        window.navigator.msSaveBlob(blobData, filename);
                    } else {
                        let downloadLink = window.document.createElement('a');
                        downloadLink.href = window.URL.createObjectURL( blobData );
                        downloadLink.download = filename;
                        document.body.appendChild(downloadLink);
                        downloadLink.click();
                        document.body.removeChild(downloadLink);
                    }
                } else {
                    swal({
                        title: this.$t('service_data'),
                        html: '<textarea cols="80" rows="30">' + response + '</textarea>',
                        width: 800,
                    });
                }
                this.$refs.sidebar.hide();
            }).fail(error => {
                window.console.log(error);
            });
        },
    },
};
</script>

<style lang="scss">
.LogExporter {
    .inline-block > * {
        display: inline;
    }
}
</style>

