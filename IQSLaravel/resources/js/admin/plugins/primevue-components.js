import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Textarea from 'primevue/textarea';
import Password from 'primevue/password';
import Checkbox from 'primevue/checkbox';
import Select from 'primevue/select';
import SelectButton from 'primevue/selectbutton';
import DatePicker from 'primevue/datepicker';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import Avatar from 'primevue/avatar';
import Menu from 'primevue/menu';
import Drawer from 'primevue/drawer';
import Chart from 'primevue/chart';
import Breadcrumb from 'primevue/breadcrumb';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import Card from 'primevue/card';
import Badge from 'primevue/badge';
import OverlayBadge from 'primevue/overlaybadge';
import Divider from 'primevue/divider';
import ProgressBar from 'primevue/progressbar';
import Skeleton from 'primevue/skeleton';
import Dialog from 'primevue/dialog';
import Toast from 'primevue/toast';
import ConfirmDialog from 'primevue/confirmdialog';
import ConfirmPopup from 'primevue/confirmpopup';
import InputNumber from 'primevue/inputnumber';
import ToggleSwitch from 'primevue/toggleswitch';
import MultiSelect from 'primevue/multiselect';
import Message from 'primevue/message';
import FileUpload from 'primevue/fileupload';
import Tabs from 'primevue/tabs';
import TabList from 'primevue/tablist';
import Tab from 'primevue/tab';
import TabPanels from 'primevue/tabpanels';
import TabPanel from 'primevue/tabpanel';

/**
 * Globally register the PrimeVue components used across the admin panel so
 * views stay clean. New components: import here once, then use in templates.
 */
export function registerComponents(app) {
    const components = {
        Button,
        InputText,
        Textarea,
        Password,
        Checkbox,
        Select,
        SelectButton,
        DatePicker,
        DataTable,
        Column,
        Tag,
        Avatar,
        Menu,
        Drawer,
        Chart,
        Breadcrumb,
        IconField,
        InputIcon,
        Card,
        Badge,
        OverlayBadge,
        Divider,
        ProgressBar,
        Skeleton,
        Dialog,
        Toast,
        ConfirmDialog,
        ConfirmPopup,
        InputNumber,
        ToggleSwitch,
        MultiSelect,
        Message,
        FileUpload,
        Tabs,
        TabList,
        Tab,
        TabPanels,
        TabPanel,
    };

    for (const [name, component] of Object.entries(components)) {
        app.component(name, component);
    }
}

export default registerComponents;
