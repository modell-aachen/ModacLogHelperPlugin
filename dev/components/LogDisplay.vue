<template>
    <div class="LogDisplay">
        <vue-header3>
            {{ logType }}
        </vue-header3>
        <vue-check-item
            v-if="columnsHash.tracestring"
            v-model="showTrace">
            {{ $t('show_trace') }}
        </vue-check-item>
        <table>
            <thead>
                <th
                    v-for="(header, idx) in columns"
                    :key="idx">
                    <span
                        v-show="header !== 'tracestring' || showTrace">
                        {{ header }}
                    </span>
                </th>
            </thead>
            <tbody>
                <tr
                    v-for="(entry, entry_idx) in logs"
                    :key="entry_idx">
                    <td
                        v-for="(header, header_idx) in columns"
                        :key="`${entry_idx} ${header_idx}`">
                        <span
                            v-if="header === 'epoch'">
                            {{ $moment(entry.epoch * 1000).format() }}
                        </span>
                        <div
                            v-else-if="header === 'extra'"
                            class="grid-x grid-margin-x">
                            <div
                                v-for="(field, field_idx) in entry.extra"
                                :key="`${entry_idx} ${header_idx} ${field_idx}`"
                                class="cell shrink auto">
                                <!-- eslint-disable-next-line vue/singleline-html-element-content-newline -->
                                <div class="field">{{ field }}</div>
                            </div>
                        </div>
                        <div
                            v-else-if="header === 'tracestring'">
                            <div
                                v-show="header !== 'tracestring' || showTrace">
                                {{ entry[header] }}
                            </div>
                        </div>
                        <div
                            v-else>
                            {{ entry[header] }}
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>

<script>
export default {
    props: {
        logs: {
            type: Array,
            default: () => [],
        },
        logType: {
            type: String,
            default: '',
        },
    },
    data() {
        return {
            showTrace: false,
        };
    },
    computed: {
        columns() {
            let columns = this.sortColumns(this.columnsHash);
            return columns;
        },
        columnsHash() {
            let collectedColumns = {};
            this.logs.forEach(row => {
                Object.keys(row).forEach(column => {
                    collectedColumns[column] = 1;
                });
            });

            return collectedColumns;
        },
    },
    methods: {
        sortColumns(columnsHash) {
            const prioritised = ['epoch', 'level', 'caller', 'user', 'action', 'webTopic', 'extra'];
            let columns = [];
            prioritised.forEach(column => {
                if(columnsHash[column]) {
                    columns.push(column);
                    delete columnsHash[column];
                }
            });
            let remaining = Object.keys(columnsHash);
            remaining = remaining.sort();
            columns = columns.concat(remaining);

            return columns;
        },
    },
};
</script>

<style lang="scss">
@import '../sass/settings';
.LogDisplay {
    .field {
        white-space: pre;
        background-color: $ma-bg-beige;
    }
}
</style>
